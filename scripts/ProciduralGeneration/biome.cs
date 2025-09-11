using Godot;
using System;

public abstract partial class Biome
{
    protected int Seed { get; set; }
    protected FastNoiseLite temperatureNoise { get; set; }
    protected FastNoiseLite moistureNoise { get; set; }
    public class TileData
    {
        public int GroundSourceID { get; set; } = -1;
        public Vector2I GroundTile { get; set; } = new Vector2I(-1, -1);
        public int GroundTileAlternative { get; set; } = 0;
        public int TreePropSourceID { get; set; } = -1;
        public Vector2I TreePropTile { get; set; } = new Vector2I(-1, -1);
        public int TreePropTileAlternative { get; set; } = 0;
    }
    public class Prop
    {
        public int sourceID;
        public Vector2I atlassCords;
        public int alternative;
        public Prop(int sourceID, Vector2I atlassCords, int alternative = 0)
        {
            this.sourceID = sourceID;
            this.atlassCords = atlassCords;
            this.alternative = alternative;
        }

        public override bool Equals(object obj)
        {
            if (obj is null) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != this.GetType()) return false;
            Prop other = (Prop)obj;
            return sourceID == other.sourceID && alternative == other.alternative && atlassCords.Equals(other.atlassCords);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(sourceID, atlassCords, alternative);
        }
    }
    public class PropCondition
    {
        public float chance;

        public PropCondition(float chance = 0f)
        {
            this.chance = chance;
        }

        public override bool Equals(object obj)
        {
            if (obj is null) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != this.GetType()) return false;
            PropCondition other = (PropCondition)obj;
            return chance == other.chance;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(
                chance
            );
        }
    }
    public Biome(int Seed, FastNoiseLite temperatureNoise, FastNoiseLite moistureNoise)
    {
        this.Seed = Seed;
        this.temperatureNoise = temperatureNoise;
        this.moistureNoise = moistureNoise;
    }
    public abstract TileData GetTileData(int x, int y);
}
