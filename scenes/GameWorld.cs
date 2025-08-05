using Godot;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public partial class GameWorld : Node2D
{
    [Export] public int Seed { get; set; } = -1;
    [Export] public int ChunksDistanceRadius { get; set; } = 3;
    [Export] public FastNoiseLite temperatureNoise = new();
    [Export] public FastNoiseLite moistureNoise = new();

    private CharacterBody2D mainCharacter;
    private CanvasLayer inGameUI;
    private TileMapLayer ground;
    private TileMapLayer treeProps;

    private FantacyForest fantacyForest;

    private const int ChunkSize = 32;
    private int tileSize;

    public class Chunk
    {
        // Ground layer
        public Vector2I[,] GroundTiles { get; private set; }
        public int[,] GroundSourceIDs { get; private set; }
        public int[,] GroundTilesAlternativeID { get; private set; }

        // Tree layer
        public Vector2I[,] TreePropsTiles { get; private set; }
        public int[,] TreePropsSourceIDs { get; private set; }
        public int[,] TreeTilesAlternativeID { get; private set; }
        public CancellationTokenSource? cancellationTokenSource = null;

        public Chunk(CancellationTokenSource token)
        {
            cancellationTokenSource = token;
            GroundTiles = new Vector2I[ChunkSize, ChunkSize];
            GroundSourceIDs = new int[ChunkSize, ChunkSize];
            GroundTilesAlternativeID = new int[ChunkSize, ChunkSize];

            TreePropsTiles = new Vector2I[ChunkSize, ChunkSize];
            TreePropsSourceIDs = new int[ChunkSize, ChunkSize];
            TreeTilesAlternativeID = new int[ChunkSize, ChunkSize];
        }
    }

    private readonly Dictionary<Vector2I, Chunk> loadedChunks = new();
    private readonly object _chunkLock = new();
    private Vector2I prevCharacterChunk = new(int.MaxValue, int.MaxValue);
    private readonly HashSet<Vector2I> _visibleChunkPositions = new();

    public override void _Ready()
    {
        mainCharacter = GetNode<CharacterBody2D>("YSorting/Player");
        inGameUI = GetNode<CanvasLayer>("Camera2D/in game UI");
        ground = GetNode<TileMapLayer>("Ground");
        treeProps = GetNode<TileMapLayer>("YSorting/Trees&StaticProps");

        Engine.MaxFps = 60;
        Engine.PhysicsTicksPerSecond = 120;

        if (Seed == -1)
            Seed = (int)GD.Randi();

        tileSize = ground.TileSet.TileSize.X;

        temperatureNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
        temperatureNoise.Frequency = 0.005f;
        temperatureNoise.Seed = Seed;
        temperatureNoise.FractalType = FastNoiseLite.FractalTypeEnum.None;

        moistureNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
        moistureNoise.Frequency = 0.01f;
        moistureNoise.Seed = Seed + 1;
        moistureNoise.FractalType = FastNoiseLite.FractalTypeEnum.None;
        fantacyForest = new FantacyForest(Seed, temperatureNoise, moistureNoise);
    }

    public override void _PhysicsProcess(double delta)
    {
        Vector2I characterChunk = new(
            Mathf.FloorToInt(mainCharacter.GlobalPosition.X / tileSize / ChunkSize),
            Mathf.FloorToInt(mainCharacter.GlobalPosition.Y / tileSize / ChunkSize)
        );
        // Only Update Chuncks if the Player gose to the new Chunck & its Speed is not too fast else the code will Load & unload the Chuncks Which will be not seen by the Player
        if (characterChunk != prevCharacterChunk && mainCharacter.Velocity.DistanceTo(Vector2.Zero) < 5000)
        {
            if (!UpdateChunks(characterChunk))
                prevCharacterChunk = characterChunk;
        }
    }

    private bool UpdateChunks(Vector2I characterChunk)
    {
        _visibleChunkPositions.Clear();

        // Identify visible chunks and start loading any that are missing.
        // Iterate outwards from the character's chunk to prioritize closer chunks.
        for (int r = 0; r <= ChunksDistanceRadius; r++)
        {
            for (int dx = -r; dx <= r; dx++)
            {
                int dyAbs = r - Math.Abs(dx);
                if (ProcessChunkPosition(characterChunk + new Vector2I(dx, dyAbs)))
                    return true;
                if (dyAbs != 0)
                {
                    if (ProcessChunkPosition(characterChunk + new Vector2I(dx, -dyAbs)))
                        return true;
                }
            }
        }

        // Identify chunks to unload using a larger radius to prevent thrashing.
        var chunksToUnload = new List<Vector2I>();
        int unloadRadius = ChunksDistanceRadius + 2;
        lock (_chunkLock)
        {
            foreach (var loadedChunkPos in loadedChunks.Keys)
            {
                // Use Manhattan distance, same as the loading logic.
                int distance = Math.Abs(loadedChunkPos.X - characterChunk.X) + Math.Abs(loadedChunkPos.Y - characterChunk.Y);
                if (distance > unloadRadius)
                {
                    chunksToUnload.Add(loadedChunkPos);
                }
            }
        }

        // Start unloading tasks. These are low priority.
        foreach (var chunkPos in chunksToUnload)
        {
            Task.Run(() => UnloadChunk(chunkPos));
            return true;
        }
        return false;
    }

    private bool ProcessChunkPosition(Vector2I chunkPos)
    {
        if (_visibleChunkPositions.Add(chunkPos)) // Add returns true if the item was new
        {
            lock (_chunkLock)
            {
                if (!loadedChunks.ContainsKey(chunkPos))
                {
                    // High priority: start loading immediately.
                    var cts = new CancellationTokenSource();
                    Chunk newChunk = new Chunk(cts);
                    loadedChunks.Add(chunkPos, newChunk);
                    Task.Run(() => LoadChunk(chunkPos, newChunk), cts.Token);
                    return true;
                }
            }
        }
        return false;
    }

    private void LoadChunk(Vector2I chunkIdx, Chunk newChunk)
    {
        var cts = newChunk.cancellationTokenSource;
        var token = newChunk.cancellationTokenSource.Token;
        if (!loadedChunks.ContainsKey(chunkIdx))
            loadedChunks.Add(chunkIdx, newChunk);

        // Generate all chunk data in the background. This is CPU intensive.
        for (int x = 0; x < ChunkSize; x++)
        {
            for (int y = 0; y < ChunkSize; y++)
            {
                if (token.IsCancellationRequested)
                {
                    // The load was cancelled (e.g., by an unload request).
                    lock (_chunkLock)
                    {
                        if (loadedChunks.ContainsKey(chunkIdx))
                        {
                            loadedChunks.Remove(chunkIdx);
                        }
                    }
                    return;
                }

                Vector2I globalTilePos = chunkIdx * ChunkSize + new Vector2I(x, y);
                Biome.TileData currentTile = fantacyForest.GetTileData(globalTilePos.X, globalTilePos.Y);

                newChunk.GroundTiles[x, y] = currentTile.GroundTile;
                newChunk.GroundSourceIDs[x, y] = currentTile.GroundSourceID;
                newChunk.GroundTilesAlternativeID[x, y] = currentTile.GroundTileAlternative;

                if (currentTile.TreePropSourceID != -1)
                {
                    newChunk.TreePropsTiles[x, y] = currentTile.TreePropTile;
                    newChunk.TreePropsSourceIDs[x, y] = currentTile.TreePropSourceID;
                    newChunk.TreeTilesAlternativeID[x, y] = currentTile.TreePropTileAlternative;
                }
                else
                {
                    newChunk.TreePropsSourceIDs[x, y] = -1; // Sentinel for no tile
                }
            }
        }

        // Mark the chunk as fully generated and no longer cancellable.
        newChunk.cancellationTokenSource = null;
        // Schedule the application of the generated data on the main thread.
        Callable.From(() => ApplyChunkData(chunkIdx, newChunk)).CallDeferred();
    }

    private void ApplyChunkData(Vector2I chunkIdx, Chunk chunk)
    {
        // This runs on the main thread.
        for (int x = 0; x < ChunkSize; x++)
        {
            for (int y = 0; y < ChunkSize; y++)
            {
                Vector2I globalTilePos = chunkIdx * ChunkSize + new Vector2I(x, y);
                ground.SetCell(globalTilePos, chunk.GroundSourceIDs[x, y], chunk.GroundTiles[x, y], chunk.GroundTilesAlternativeID[x, y]);

                if (chunk.TreePropsSourceIDs[x, y] != -1)
                {
                    treeProps.SetCell(globalTilePos, chunk.TreePropsSourceIDs[x, y], chunk.TreePropsTiles[x, y], chunk.TreeTilesAlternativeID[x, y]);
                }
            }
        }
    }

    private void UnloadChunk(Vector2I chunkIdx)
    {
        Chunk chunkToUnload;
        lock (_chunkLock)
        {
            if (!loadedChunks.TryGetValue(chunkIdx, out chunkToUnload))
            {
                return; // Already unloaded.
            }
            loadedChunks.Remove(chunkIdx);
        }

        chunkToUnload.cancellationTokenSource?.Cancel();
        Callable.From(() => EraseChunkTiles(chunkIdx)).CallDeferred();
    }

    private void EraseChunkTiles(Vector2I chunkIdx)
    {
        // This runs on the main thread.
        for (int x = 0; x < ChunkSize; x++)
        {
            for (int y = 0; y < ChunkSize; y++)
            {
                Vector2I globalTilePos = chunkIdx * ChunkSize + new Vector2I(x, y);
                ground.EraseCell(globalTilePos);
                treeProps.EraseCell(globalTilePos);
            }
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            this.ProcessMode = ProcessModeEnum.Disabled;
            this.SetProcessInput(false);

            inGameUI.Show();
            inGameUI.ProcessMode = ProcessModeEnum.Always;
            inGameUI.SetProcessInput(true);
        }
    }
}
