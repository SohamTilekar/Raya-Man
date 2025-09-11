using Godot;
using System.Collections.Generic;
using PropCondition = FantacyForest.PropCondition;
using Prop = FantacyForest.Prop;
using TileChance = System.Tuple<float, Godot.Vector2I>;
using PropList = System.Collections.Generic.List<FantacyForest.Prop>;
using PropData = System.Tuple<FantacyForest.PropCondition, System.Collections.Generic.List<FantacyForest.Prop>>;

public static partial class FantacyForestSettings
{
    public static int fantacyForestGroundSourceID => 1;
    public static Vector2I fantacyForestGrass => new Vector2I(1, 1);
    public static Vector2I fantacyForestGrass_DirtLeft => new Vector2I(0, 4);
    public static Vector2I fantacyForestGrass_DirtRight => new Vector2I(2, 4);
    public static Vector2I fantacyForestGrass_DirtUp => new Vector2I(1, 3);
    public static Vector2I fantacyForestGrass_DirtUpLeft => new Vector2I(0, 3);
    public static Vector2I fantacyForestGrass_DirtUpRight => new Vector2I(2, 3);
    public static Vector2I fantacyForestGrass_DirtDown => new Vector2I(1, 5);
    public static Vector2I fantacyForestGrass_DirtDownLeft => new Vector2I(0, 5);
    public static Vector2I fantacyForestGrass_DirtDownRight => new Vector2I(2, 5);
    public static Vector2I fantacyForestGrass_DirtUpDown => new Vector2I(6, 4);
    public static Vector2I fantacyForestGrass_DirtUpDownRight => new Vector2I(7, 4);
    public static Vector2I fantacyForestGrass_DirtUpDownLeft => new Vector2I(5, 4);
    public static Vector2I fantacyForestGrass_DirtRightLeft => new Vector2I(5, 2);
    public static Vector2I fantacyForestGrass_DirtRightLeftUp => new Vector2I(5, 1);
    public static Vector2I fantacyForestGrass_DirtRightLeftDown => new Vector2I(5, 3);
    public static Vector2I fantacyForestGrass_DirtBottomRightCorner => new Vector2I(3, 3);
    public static Vector2I fantacyForestGrass_DirtBottomLeftCorner => new Vector2I(4, 3);
    public static Vector2I fantacyForestGrass_DirtTopRightCorner => new Vector2I(3, 4);
    public static Vector2I fantacyForestGrass_DirtTopLeftCorner => new Vector2I(4, 4);
    public static List<TileChance> fantacyForestDirt => new List<TileChance>() {
        new TileChance(0.9f, new Vector2I(5, 0)),
        new TileChance(0.05f, new Vector2I(6, 0)),
        new TileChance(0.05f, new Vector2I(7, 0))
    };
    public static List<TileChance> fantacyForestWater => new List<TileChance>() {
        new TileChance(0.9f, new Vector2I(1, 7)),
        new TileChance(0.05f, new Vector2I(6, 6)),
        new TileChance(0.05f, new Vector2I(7, 6))
    };
    public static Vector2I fantacyForestWater_BottomRightCorner => new Vector2I(4, 9);
    public static Vector2I fantacyForestWater_BottomLeftCorner => new Vector2I(5, 9);
    public static Vector2I fantacyForestWater_TopRightCorner => new Vector2I(4, 10);
    public static Vector2I fantacyForestWater_TopLeftCorner => new Vector2I(5, 10);
    public static Vector2I fantacyForestWater_Bottom_LeftRightCorner => new Vector2I(6, 12);
    public static Vector2I fantacyForestWater_Top_LeftRightCorner => new Vector2I(6, 13);
    public static Vector2I fantacyForestWater_Right_TopBottomCorner => new Vector2I(4, 11);
    public static Vector2I fantacyForestWater_Left_TopBottomCorner => new Vector2I(5, 11);
    public static Vector2I fantacyForestWater_DirtLeft => new Vector2I(3, 7);
    public static Vector2I fantacyForestWater_DirtRight => new Vector2I(5, 7);
    public static Vector2I fantacyForestWater_DirtUp => new Vector2I(4, 6);
    public static Vector2I fantacyForestWater_DirtUpLeft => new Vector2I(3, 6);
    public static Vector2I fantacyForestWater_DirtUpRight => new Vector2I(5, 6);
    public static Vector2I fantacyForestWater_DirtDown => new Vector2I(4, 8);
    public static Vector2I fantacyForestWater_DirtDownLeft => new Vector2I(3, 8);
    public static Vector2I fantacyForestWater_DirtDownRight => new Vector2I(5, 8);
    public static Vector2I fantacyForestWater_DirtUpDown => new Vector2I(0, 9);
    public static Vector2I fantacyForestWater_DirtUpDownRight => new Vector2I(1, 11);
    public static Vector2I fantacyForestWater_DirtUpDownLeft => new Vector2I(0, 11);
    public static Vector2I fantacyForestWater_DirtRightLeftUp => new Vector2I(1, 9);
    public static Vector2I fantacyForestWater_DirtRightLeft => new Vector2I(0, 10);
    public static Vector2I fantacyForestWater_DirtRightLeftDown => new Vector2I(1, 10);

    public static Vector2I fantacyForestWater_GrassUp => new Vector2I(1, 6);
    public static Vector2I fantacyForestWater_GrassUpLeft => new Vector2I(0, 6);
    public static Vector2I fantacyForestWater_GrassUpRight => new Vector2I(2, 6);
    public static Vector2I fantacyForestWater_GrassLeft => new Vector2I(0, 7);
    public static Vector2I fantacyForestWater_GrassRight => new Vector2I(2, 7);
    public static Vector2I fantacyForestWater_GrassDownLeft => new Vector2I(0, 8);
    public static Vector2I fantacyForestWater_GrassDown => new Vector2I(1, 8);
    public static Vector2I fantacyForestWater_GrassDownRight => new Vector2I(2, 8);
    public static Vector2I fantacyForestWater_GrassUpDown => new Vector2I(2, 9);
    public static Vector2I fantacyForestWater_GrassUpDownRight => new Vector2I(3, 11);
    public static Vector2I fantacyForestWater_GrassUpDownLeft => new Vector2I(2, 11);
    public static Vector2I fantacyForestWater_GrassRightLeftUp => new Vector2I(3, 9);
    public static Vector2I fantacyForestWater_GrassRightLeft => new Vector2I(2, 10);
    public static Vector2I fantacyForestWater_GrassRightLeftDown => new Vector2I(3, 10);
    // This is for if the conditions for the multiple props is same than the only 1 will be choosed again & again to spawn
    public static List<PropData> fantacyForestPropsWithChance => new List<PropData>()
    {
        new PropData(// Trees
            new PropCondition(
                chance: 0.1f,
                chanceAsFertility: new List<AkashCurvePoint>() {
                    new AkashCurvePoint(new Vector2(0.402f, 0.031f)),
                    new AkashCurvePoint(new Vector2(1f, 0.09f)),
                    new AkashCurvePoint(new Vector2(0f, 0f), right_tangent: 0.165f),
                },
                grassProp: true,
                priority: 1024
            ),
            new PropList() {
                new Prop(1, new Vector2I(0, 0)),
                new Prop(1, new Vector2I(5, 0)),
                new Prop(1, new Vector2I(8, 0)),
                new Prop(1, new Vector2I(11, 0)),
                new Prop(1, new Vector2I(15, 0)),
                new Prop(1, new Vector2I(21, 0)),
                new Prop(1, new Vector2I(25, 0)),
                new Prop(1, new Vector2I(30, 0)),
                new Prop(1, new Vector2I(36, 0)),
                new Prop(1, new Vector2I(41, 0)),
                new Prop(1, new Vector2I(0, 7)),
                new Prop(1, new Vector2I(5, 5)),
                new Prop(1, new Vector2I(8, 6)),
                new Prop(1, new Vector2I(13, 6)),
                new Prop(1, new Vector2I(17, 6)),
                new Prop(1, new Vector2I(21, 6)),
                new Prop(1, new Vector2I(25, 6)),
                new Prop(1, new Vector2I(30, 5)),
                new Prop(1, new Vector2I(34, 5)),
                new Prop(1, new Vector2I(38, 5)),
                new Prop(1, new Vector2I(43, 5)),
                new Prop(1, new Vector2I(5, 10)),
                new Prop(1, new Vector2I(10, 10)),
                new Prop(1, new Vector2I(17, 10)),
                new Prop(1, new Vector2I(22, 10)),
                new Prop(1, new Vector2I(31, 10)),
                new Prop(1, new Vector2I(36, 10)),
                new Prop(1, new Vector2I(42, 10)),
                new Prop(1, new Vector2I(13, 11)),
                new Prop(1, new Vector2I(0, 13)),
                new Prop(1, new Vector2I(5, 16)),
            }
        ),
        // {// Big Bushes
        //     new PropCondition(
        //         chance: 0.05f,
        //         chanceAsFertility: new List<AkashCurvePoint>() {},
        //         grassProp: true,
        //         priority: 1000
        //     ),
        //     new PropList() {
        //         new Prop(2, new Vector2I(0, 0)),
        //         new Prop(2, new Vector2I(3, 0)),
        //         new Prop(2, new Vector2I(5, 0)),
        //         new Prop(2, new Vector2I(0, 2)),
        //         new Prop(2, new Vector2I(2, 2)),
        //         new Prop(2, new Vector2I(4, 2)),
        //         new Prop(2, new Vector2I(0, 4)),
        //         new Prop(2, new Vector2I(2, 4)),
        //         new Prop(2, new Vector2I(4, 4)),
        //         new Prop(2, new Vector2I(0, 6)),
        //         new Prop(2, new Vector2I(2, 6)),
        //         new Prop(2, new Vector2I(0, 8)),
        //         new Prop(2, new Vector2I(3, 8)),
        //     }
        // },
        // {// Small Bushes
        //     new PropCondition(
        //         chance: 0.09f,
        //         chanceAsFertility: new List<AkashCurvePoint>() {},
        //         grassProp: true,
        //         priority: 900
        //     ),
        //     new PropList() {
        //         new Prop(2, new Vector2I(7, 0)),
        //         new Prop(2, new Vector2I(7, 1)),
        //         new Prop(2, new Vector2I(7, 2)),
        //         new Prop(2, new Vector2I(7, 3)),
        //         new Prop(2, new Vector2I(7, 4)),
        //         new Prop(2, new Vector2I(7, 5)),
        //         new Prop(2, new Vector2I(7, 6)),
        //         new Prop(2, new Vector2I(6, 2)),
        //         new Prop(2, new Vector2I(6, 3)),
        //         new Prop(2, new Vector2I(6, 4)),
        //         new Prop(2, new Vector2I(6, 5)),
        //         new Prop(2, new Vector2I(6, 6)),
        //         new Prop(2, new Vector2I(6, 7)),
        //         new Prop(2, new Vector2I(5, 6)),
        //         new Prop(2, new Vector2I(5, 7)),
        //     }
        // },
        // {// Pables In Dirt
        //     new PropCondition(
        //         chance: 0.1f,
        //         dirtProp: true,
        //         priority: 900
        //     ),
        //     new PropList() {
        //         new Prop(4, new Vector2I(3, 0)),
        //         new Prop(4, new Vector2I(4, 0)),
        //         new Prop(4, new Vector2I(5, 0)),
        //         new Prop(4, new Vector2I(6, 0)),
        //         new Prop(4, new Vector2I(3, 1)),
        //         new Prop(4, new Vector2I(4, 1)),
        //         new Prop(4, new Vector2I(5, 1)),
        //         new Prop(4, new Vector2I(6, 1)),
        //         new Prop(4, new Vector2I(4, 2)),
        //         new Prop(4, new Vector2I(4, 4)),
        //     }
        // },
        // {// Big Rocks in dirt
        //     new PropCondition(
        //         chance: 0.05f,
        //         dirtProp: true,
        //         priority: 1000
        //     ),
        //     new PropList() {
        //         new Prop(4, new Vector2I(0, 0)),
        //         new Prop(4, new Vector2I(2, 0)),
        //         new Prop(4, new Vector2I(2, 1)),
        //         new Prop(4, new Vector2I(0, 2)),
        //         new Prop(4, new Vector2I(2, 2)),
        //         new Prop(4, new Vector2I(0, 4)),
        //         new Prop(4, new Vector2I(2, 4)),
        //         new Prop(4, new Vector2I(4, 8)),
        //         new Prop(4, new Vector2I(2, 10)),
        //     }
        // },
        // {// Rocks & pables on Grass
        //     new PropCondition(
        //         chance: 0.04f,
        //         chanceAsFertility: new List<AkashCurvePoint>() {},
        //         fertilityThreasholdGT: 0.1f,
        //         grassProp: true,
        //         priority: 600
        //     ),
        //     new PropList() {
        //         new Prop(4, new Vector2I(2, 5)),
        //         new Prop(4, new Vector2I(3, 5)),
        //         new Prop(4, new Vector2I(4, 5)),
        //         new Prop(4, new Vector2I(5, 5)),
        //         new Prop(4, new Vector2I(2, 6)),
        //         new Prop(4, new Vector2I(0, 7)),
        //         new Prop(4, new Vector2I(2, 7)),
        //         new Prop(4, new Vector2I(4, 7)),
        //         new Prop(4, new Vector2I(2, 8)),
        //         new Prop(4, new Vector2I(0, 9)),
        //         new Prop(4, new Vector2I(4, 10)),
        //         new Prop(4, new Vector2I(0, 11)),
        //         new Prop(4, new Vector2I(2, 11)),
        //         new Prop(4, new Vector2I(4, 11)),
        //         new Prop(4, new Vector2I(0, 13)),
        //         new Prop(4, new Vector2I(2, 13)),
        //         new Prop(4, new Vector2I(4, 13)),
        //         new Prop(4, new Vector2I(0, 15)),
        //     }
        // },
        // {// Grass near lake
        //     new PropCondition(
        //         chance: 0.4f,
        //         moistureThreasholdGT: 0.87f,
        //         chanceAsMoisture: new List<AkashCurvePoint>() {},
        //         grassProp: true,
        //         allowOnTileBorders: true,
        //         priority: 1000
        //     ),
        //     new PropList() {
        //         new Prop(5, new Vector2I(0, 0)),
        //         new Prop(5, new Vector2I(2, 0)),
        //         new Prop(5, new Vector2I(0, 2)),
        //         new Prop(5, new Vector2I(2, 2)),
        //         new Prop(5, new Vector2I(4, 2)),
        //         new Prop(5, new Vector2I(6, 2)),
        //         new Prop(5, new Vector2I(7, 2)),
        //         new Prop(5, new Vector2I(8, 2)),
        //         new Prop(5, new Vector2I(9, 2)),
        //         new Prop(5, new Vector2I(11, 2)),
        //         new Prop(5, new Vector2I(13, 2)),
        //     }
        // },
        // {// Grass
        //     new PropCondition(
        //         chance: 0.6f,
        //         // chanceAsFertility: new List<AkashCurvePoint>() {},
        //         grassProp: true,
        //         priority: -1204
        //     ),
        //     new PropList() {
        //         new Prop(6, new Vector2I(0, 0)),
        //         new Prop(6, new Vector2I(0, 0), 1),
        //         new Prop(6, new Vector2I(1, 0)),
        //         new Prop(6, new Vector2I(1, 0), 1)
        //     }
        // },
        // {
        //     new PropCondition(
        //         chance: 0.02f,
        //         waterProp: true,
        //         priority: 1000
        //     ),
        //     new PropList() {
        //         new Prop(7, new Vector2I(0, 0)),
        //         new Prop(7, new Vector2I(0, 0), 1),
        //         new Prop(7, new Vector2I(1, 0)),
        //         new Prop(7, new Vector2I(1, 0), 1),
        //     }
        // }
    };
}
