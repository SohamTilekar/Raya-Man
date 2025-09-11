using System.Collections.Generic;
using System;

public static partial class NoiseUtil
{
    public static int WhiteNoise(params int[] seeds)
    {
        unchecked
        {
            const uint C1 = 0xcc9e2d51;
            const uint C2 = 0x1b873593;
            const int R1 = 15; // Rotation for k1
            const int R2 = 13; // Rotation for h1
            const uint M = 5;
            const uint N = 0xe6546b64;

            uint h1 = 0x9747b28c;

            foreach (int seedVal in seeds)
            {
                uint k1 = (uint)seedVal;

                k1 *= C1;
                k1 = (k1 << R1) | (k1 >> (32 - R1));
                k1 *= C2;

                h1 ^= k1;
                h1 = (h1 << R2) | (h1 >> (32 - R2));
                h1 = h1 * M + N;
            }

            h1 ^= (uint)(seeds.Length * 4);
            h1 ^= h1 >> 16;
            h1 *= 0x85ebca6b;
            h1 ^= h1 >> 13;
            h1 *= 0xc2b2ae35;
            h1 ^= h1 >> 16;

            return (int)h1;
        }
    }

    public static int WhiteNoiseMax(uint maxExclusive, params int[] seeds)
    {
        if (maxExclusive == 0)
            throw new ArgumentOutOfRangeException(nameof(maxExclusive), "maxExclusive must be > 0");

        unchecked
        {
            uint raw = (uint)WhiteNoise(seeds);
            return (int)(raw % maxExclusive);
        }
    }

    public static bool CheckChance(float chance, params int[] seeds)
    {
        if (chance < 0f || chance > 1f)
            throw new ArgumentOutOfRangeException(nameof(chance), "Chance must be between 0 and 1.");

        if (chance == 0f) return false;
        if (chance == 1f) return true;

        uint raw = (uint)WhiteNoise(seeds);
        float normalized = raw / (float)uint.MaxValue;
        return normalized < chance;
    }

    public static TResult GetWeightedRandomElement<TResult>(List<Tuple<float, TResult>> weightedList, params int[] seeds)
    {
        if (weightedList == null || weightedList.Count == 0)
        {
            throw new ArgumentException("Weighted list cannot be null or empty.", nameof(weightedList));
        }

        float totalWeight = 0f;
        foreach (var item in weightedList)
        {
            totalWeight += item.Item1;
        }

        if (totalWeight <= 0f)
        {
            throw new ArgumentException("Total probability must be greater than 0.", nameof(weightedList));
        }

        uint rawNoise = (uint)WhiteNoise(seeds);
        float randomValue = rawNoise / (float)uint.MaxValue * totalWeight;

        float currentSum = 0f;
        for (int i = 0; i < weightedList.Count; i++)
        {
            currentSum += weightedList[i].Item1;
            if (randomValue < currentSum)
            {
                return weightedList[i].Item2;
            }
        }

        return weightedList[0].Item2;
    }
}
