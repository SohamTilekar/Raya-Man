#nullable enable
using Godot;
using System;
using System.Collections.Generic;
using static FantacyForestSettings;

public partial class FantacyForest : Biome
{
    protected FastNoiseLite fertilityNoise;
    protected FastNoiseLite dirtPatchNoise;
    public new class PropCondition : Biome.PropCondition
    {
        public Godot.Curve? chanceAsFertility = null; // Use the Curve to remap chance * multiply with chance
        public Godot.Curve? chanceAsMoisture = null; // Use the Curve to remap chance * multiply with chance
        public float fertilityThreasholdGT = -1f; // Disable using -1f.
        public float fertilityThreasholdLT = -1f; // Disable using -1f.
        public float moistureThreasholdGT = -1f; // Disable using -1f.
        public float moistureThreasholdLT = -1f; // Disable using -1f.
        public bool waterProp = false;
        public bool dirtProp = false;
        public bool grassProp = false;
        public int priority = 0; // Highest priority prop is chosen for a tile. Random if equal.
        public bool allowOnTileBorders = false; // Allow placement even if surrounding tiles differ.

        public PropCondition(float chance = 0f,
                            List<AkashCurvePoint>? chanceAsFertility = null, List<AkashCurvePoint>? chanceAsMoisture = null,
                            float fertilityThreasholdGT = -1f, float fertilityThreasholdLT = -1f,
                            float moistureThreasholdGT = -1f, float moistureThreasholdLT = -1f,
                            bool waterProp = false, bool dirtProp = false, bool grassProp = false, int priority = 0, bool allowOnTileBorders = false) : base(chance)
        {
            if (chanceAsFertility != null)
            {
                this.chanceAsFertility = new Godot.Curve();
                // this.chanceAsFertility.BakeResolution = 50;
                foreach (var point in chanceAsFertility)
                {
                    this.chanceAsFertility.AddPoint(point.position, point.left_tangent, point.right_tangent, point.left_mode, point.right_mode);
                }
            }
            if (chanceAsMoisture != null)
            {
                this.chanceAsMoisture = new Godot.Curve();
                // this.chanceAsMoisture.BakeResolution = 50;
                foreach (var point in chanceAsMoisture)
                {
                    this.chanceAsMoisture.AddPoint(point.position, point.left_tangent, point.right_tangent, point.left_mode, point.right_mode);
                }
                // this.chanceAsMoisture.Bake();
            }
            this.fertilityThreasholdGT = fertilityThreasholdGT;
            this.fertilityThreasholdLT = fertilityThreasholdLT;
            this.moistureThreasholdGT = moistureThreasholdGT;
            this.moistureThreasholdLT = moistureThreasholdLT;
            this.waterProp = waterProp;
            this.dirtProp = dirtProp;
            this.grassProp = grassProp;
            this.priority = priority;
            this.allowOnTileBorders = allowOnTileBorders;
        }

        public override bool Equals(object obj)
        {
            if (obj is null) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != this.GetType()) return false;
            PropCondition other = (PropCondition)obj;
            return chance == other.chance &&
                   chanceAsFertility == other.chanceAsFertility &&
                   chanceAsMoisture == other.chanceAsMoisture &&
                   fertilityThreasholdGT == other.fertilityThreasholdGT &&
                   fertilityThreasholdLT == other.fertilityThreasholdLT &&
                   moistureThreasholdGT == other.moistureThreasholdGT &&
                   moistureThreasholdLT == other.moistureThreasholdLT &&
                   waterProp == other.waterProp &&
                   dirtProp == other.dirtProp &&
                   grassProp == other.grassProp &&
                   priority == other.priority &&
                   allowOnTileBorders == other.allowOnTileBorders;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(
                HashCode.Combine(
                    chance,
                    chanceAsFertility,
                    chanceAsMoisture,
                    fertilityThreasholdGT,
                    fertilityThreasholdLT,
                    moistureThreasholdGT,
                    moistureThreasholdLT,
                    priority
                ),
                HashCode.Combine(
                    waterProp,
                    dirtProp,
                    grassProp,
                    allowOnTileBorders
                )
            );
        }
    }
    public FantacyForest(int Seed, FastNoiseLite temperatureNoise, FastNoiseLite moistureNoise, FastNoiseLite? localFertilityNoise = null, FastNoiseLite? localDirtPatchNoise = null) : base(Seed, temperatureNoise, moistureNoise)
    {
        if (localFertilityNoise != null)
            fertilityNoise = localFertilityNoise;
        else
        {
            fertilityNoise = new FastNoiseLite();
            fertilityNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
            fertilityNoise.Frequency = 0.015f;
            fertilityNoise.Seed = Seed + 2;
            fertilityNoise.FractalType = FastNoiseLite.FractalTypeEnum.None;
        }
        if (localDirtPatchNoise != null)
            dirtPatchNoise = localDirtPatchNoise;
        else
        {
            dirtPatchNoise = new FastNoiseLite();
            dirtPatchNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
            dirtPatchNoise.Frequency = 0.02f;
            dirtPatchNoise.Seed = Seed + 2;
            dirtPatchNoise.FractalType = FastNoiseLite.FractalTypeEnum.None;
        }
    }
    private float GetFertilityNoise(int x, int y)
    {
        float baseFertility = fertilityNoise.GetNoise2D(x, y);
        float dirtValue = dirtPatchNoise.GetNoise2D(x, y);
        if (dirtValue > 0.4f)
        {
            baseFertility = Mathf.Lerp(baseFertility, -1, dirtValue * (2 - dirtValue));
        }
        return baseFertility;
    }
    public override TileData GetTileData(int x, int y)
    {
        TileData tileData = new TileData();
        tileData.GroundSourceID = fantacyForestGroundSourceID;

        // Define tile types as constants for readability.
        const int TILE_TYPE_DIRT = 0;
        const int TILE_TYPE_GRASS = 1;
        const int TILE_TYPE_WATER = 3;

        // Helper function to determine the base tile type at a coordinate using noise.
        // This makes the generation deterministic.
        Func<int, int, int> getTileType = (tileX, tileY) =>
        {
            float currentMoistureNoise = moistureNoise.GetNoise2D(tileX, tileY);
            if (currentMoistureNoise > 0.8) return TILE_TYPE_WATER;
            if (currentMoistureNoise < 0.6 && dirtPatchNoise.GetNoise2D(tileX, tileY) > 0.9) return TILE_TYPE_DIRT;
            return TILE_TYPE_GRASS;
        };

        int currentTileType = getTileType(x, y);
        float currentFertilityNoiseValue = GetFertilityNoise(x, y);
        float normalizedCurrentFertilityNoiseValue = (currentFertilityNoiseValue + 1f) / 2f; // Normalized from -1 to 1 to 0 to 1
        float currentMoistureNoiseValue = moistureNoise.GetNoise2D(x, y);
        float normalizedCurrentMoistureNoiseValue = (currentMoistureNoiseValue + 1f) / 2f; // Normalized from -1 to 1 to 0 to 1

        int upType = getTileType(x, y - 1);
        int downType = getTileType(x, y + 1);
        int leftType = getTileType(x - 1, y);
        int rightType = getTileType(x + 1, y);

        List<Prop> allEligiblePropsForThisCell = new List<Prop>();
        int higestPriority = int.MinValue;
        foreach (var entry in fantacyForestPropsWithChance)
        {
            PropCondition condition = entry.Item1;
            List<Prop> propsFromThisCondition = entry.Item2;

            if (
                (condition.dirtProp && currentTileType != TILE_TYPE_DIRT)
                || (condition.waterProp && currentTileType != TILE_TYPE_WATER)
                || (condition.grassProp && currentTileType != TILE_TYPE_GRASS)
            )
                continue;

            if (condition.fertilityThreasholdGT != -1f && normalizedCurrentFertilityNoiseValue <= condition.fertilityThreasholdGT)
                continue;
            if (condition.fertilityThreasholdLT != -1f && normalizedCurrentFertilityNoiseValue >= condition.fertilityThreasholdLT)
                continue;

            if (condition.moistureThreasholdGT != -1f && normalizedCurrentMoistureNoiseValue <= condition.moistureThreasholdGT)
                continue;
            if (condition.moistureThreasholdLT != -1f && normalizedCurrentMoistureNoiseValue >= condition.moistureThreasholdLT)
                continue;
            if (!(condition.allowOnTileBorders || (currentTileType == upType && currentTileType == downType && currentTileType == leftType && currentTileType == rightType)))
                continue;

            float currentChance = condition.chance;
            if (condition.chanceAsFertility != null)
            {
                currentChance *= condition.chanceAsFertility.Sample(normalizedCurrentFertilityNoiseValue);
                // currentChance *= 0.1f;
            }
            if (condition.chanceAsMoisture != null)
            {
                currentChance *= condition.chanceAsMoisture.Sample(normalizedCurrentMoistureNoiseValue);
            }

            // Clamp chance to [0, 1] to ensure it's a valid probability
            currentChance = Mathf.Clamp(currentChance, 0f, 1f);

            if (NoiseUtil.CheckChance(currentChance, x, y, condition.GetHashCode())) // Multiple Props can Have almost same condition
                if (condition.priority > higestPriority)
                    allEligiblePropsForThisCell = propsFromThisCondition;
                else if (condition.priority == higestPriority)
                    allEligiblePropsForThisCell.AddRange(propsFromThisCondition);
        }

        // After checking all conditions, if one or more props are eligible, select one deterministically.
        if (allEligiblePropsForThisCell.Count > 0)
        {
            // Select a single prop from the merged list of all eligible props.
            // The selection is deterministic based on the cell's coordinates (x, y).
            int selectedPropIndex = NoiseUtil.WhiteNoiseMax((uint)allEligiblePropsForThisCell.Count, x, y);
            Prop selectedProp = allEligiblePropsForThisCell[selectedPropIndex];

            tileData.TreePropSourceID = selectedProp.sourceID;
            tileData.TreePropTile = selectedProp.atlassCords;
            tileData.TreePropTileAlternative = selectedProp.alternative;
        }

        Func<int, int> calculateMask = (int type) =>
        {
            return ((upType == type) ? 1 : 0) |
                           ((downType == type) ? 2 : 0) |
                           ((leftType == type) ? 4 : 0) |
                           ((rightType == type) ? 8 : 0);
        };

        switch (currentTileType)
        {
            case TILE_TYPE_DIRT:
                tileData.GroundTile = NoiseUtil.GetWeightedRandomElement(fantacyForestDirt, x, y);
                break;
            case TILE_TYPE_GRASS:
                int dirtMask = calculateMask(TILE_TYPE_DIRT);
                if (dirtMask > 0)
                    switch (dirtMask)
                    {
                        case 1: tileData.GroundTile = fantacyForestGrass_DirtUp; break;
                        case 2: tileData.GroundTile = fantacyForestGrass_DirtDown; break;
                        case 3: tileData.GroundTile = fantacyForestGrass_DirtUpDown; break;
                        case 4: tileData.GroundTile = fantacyForestGrass_DirtLeft; break;
                        case 5: tileData.GroundTile = fantacyForestGrass_DirtUpLeft; break;
                        case 6: tileData.GroundTile = fantacyForestGrass_DirtDownLeft; break;
                        case 7: tileData.GroundTile = fantacyForestGrass_DirtUpDownLeft; break;
                        case 8: tileData.GroundTile = fantacyForestGrass_DirtRight; break;
                        case 9: tileData.GroundTile = fantacyForestGrass_DirtUpRight; break;
                        case 10: tileData.GroundTile = fantacyForestGrass_DirtDownRight; break;
                        case 11: tileData.GroundTile = fantacyForestGrass_DirtUpDownRight; break;
                        case 12: tileData.GroundTile = fantacyForestGrass_DirtRightLeft; break;
                        case 13: tileData.GroundTile = fantacyForestGrass_DirtRightLeftUp; break;
                        case 14: tileData.GroundTile = fantacyForestGrass_DirtRightLeftDown; break;
                        default: tileData.GroundTile = fantacyForestGrass; break;
                    }
                else
                {
                    if (getTileType(x - 1, y - 1) == TILE_TYPE_DIRT)
                        tileData.GroundTile = fantacyForestGrass_DirtTopLeftCorner;
                    else if (getTileType(x + 1, y - 1) == TILE_TYPE_DIRT)
                        tileData.GroundTile = fantacyForestGrass_DirtTopRightCorner;
                    else if (getTileType(x - 1, y + 1) == TILE_TYPE_DIRT)
                        tileData.GroundTile = fantacyForestGrass_DirtBottomLeftCorner;
                    else if (getTileType(x + 1, y + 1) == TILE_TYPE_DIRT)
                        tileData.GroundTile = fantacyForestGrass_DirtBottomRightCorner;
                    else
                        tileData.GroundTile = fantacyForestGrass;
                }
                break;
            case TILE_TYPE_WATER:
                int waterDirtMask = calculateMask(TILE_TYPE_DIRT);
                int waterGrassMask = calculateMask(TILE_TYPE_GRASS);
                var currentWatterTile = NoiseUtil.GetWeightedRandomElement(fantacyForestWater, x, y);
                if (waterDirtMask > 0)
                    switch (waterDirtMask)
                    {
                        case 1: tileData.GroundTile = fantacyForestWater_DirtUp; break;
                        case 2: tileData.GroundTile = fantacyForestWater_DirtDown; break;
                        case 3: tileData.GroundTile = fantacyForestWater_DirtUpDown; break;
                        case 4: tileData.GroundTile = fantacyForestWater_DirtLeft; break;
                        case 5: tileData.GroundTile = fantacyForestWater_DirtUpLeft; break;
                        case 6: tileData.GroundTile = fantacyForestWater_DirtDownLeft; break;
                        case 7: tileData.GroundTile = fantacyForestWater_DirtUpDownLeft; break;
                        case 8: tileData.GroundTile = fantacyForestWater_DirtRight; break;
                        case 9: tileData.GroundTile = fantacyForestWater_DirtUpRight; break;
                        case 10: tileData.GroundTile = fantacyForestWater_DirtDownRight; break;
                        case 11: tileData.GroundTile = fantacyForestWater_DirtUpDownRight; break;
                        case 12: tileData.GroundTile = fantacyForestWater_DirtRightLeft; break;
                        case 13: tileData.GroundTile = fantacyForestWater_DirtRightLeftUp; break;
                        case 14: tileData.GroundTile = fantacyForestWater_DirtRightLeftDown; break;
                        default: tileData.GroundTile = currentWatterTile; break;
                    }
                else if (waterGrassMask > 0)
                    switch (waterGrassMask)
                    {
                        case 1: tileData.GroundTile = fantacyForestWater_GrassUp; break;
                        case 2: tileData.GroundTile = fantacyForestWater_GrassDown; break;
                        case 3: tileData.GroundTile = fantacyForestWater_GrassUpDown; break;
                        case 4: tileData.GroundTile = fantacyForestWater_GrassLeft; break;
                        case 5: tileData.GroundTile = fantacyForestWater_GrassUpLeft; break;
                        case 6: tileData.GroundTile = fantacyForestWater_GrassDownLeft; break;
                        case 7: tileData.GroundTile = fantacyForestWater_GrassUpDownLeft; break;
                        case 8: tileData.GroundTile = fantacyForestWater_GrassRight; break;
                        case 9: tileData.GroundTile = fantacyForestWater_GrassUpRight; break;
                        case 10: tileData.GroundTile = fantacyForestWater_GrassDownRight; break;
                        case 11: tileData.GroundTile = fantacyForestWater_GrassUpDownRight; break;
                        case 12: tileData.GroundTile = fantacyForestWater_GrassRightLeft; break;
                        case 13: tileData.GroundTile = fantacyForestWater_GrassRightLeftUp; break;
                        case 14: tileData.GroundTile = fantacyForestWater_GrassRightLeftDown; break;
                        default: tileData.GroundTile = currentWatterTile; break;
                    }
                else
                {
                    int diagonalMask = 0;
                    if (getTileType(x - 1, y - 1) != TILE_TYPE_WATER) diagonalMask |= 1; // Top-Left
                    if (getTileType(x + 1, y - 1) != TILE_TYPE_WATER) diagonalMask |= 2; // Top-Right
                    if (getTileType(x - 1, y + 1) != TILE_TYPE_WATER) diagonalMask |= 4; // Bottom-Left
                    if (getTileType(x + 1, y + 1) != TILE_TYPE_WATER) diagonalMask |= 8; // Bottom-Right

                    switch (diagonalMask)
                    {
                        case 0: tileData.GroundTile = currentWatterTile; break;
                        case 1: tileData.GroundTile = fantacyForestWater_TopLeftCorner; break;
                        case 2: tileData.GroundTile = fantacyForestWater_TopRightCorner; break;
                        case 3: tileData.GroundTile = fantacyForestWater_Top_LeftRightCorner; break;
                        case 4: tileData.GroundTile = fantacyForestWater_BottomLeftCorner; break;
                        case 5: tileData.GroundTile = fantacyForestWater_Left_TopBottomCorner; break;
                        case 8: tileData.GroundTile = fantacyForestWater_BottomRightCorner; break;
                        case 10: tileData.GroundTile = fantacyForestWater_Right_TopBottomCorner; break;
                        case 12: tileData.GroundTile = fantacyForestWater_Bottom_LeftRightCorner; break;
                        default: tileData.GroundTile = currentWatterTile; break;
                    }
                }
                break;
            default:
                // Fallback for any unexpected tile type.
                tileData.GroundTile = fantacyForestGrass;
                break;
        }
        return tileData;
    }
};
