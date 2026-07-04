# Biomes and Kingdoms

## 1. Procedural Generation Engine
The world map is not static. Upon creating a new game, the engine generates a massive continent using noise algorithms (e.g., Perlin noise) to place biomes, rivers, mountains, and kingdoms.

## 2. Biomes
Different biomes contain different resources, monster spawn tables, and environmental hazards.

- **The Whispering Plains:** Safe beginner zones. Mostly F and E rank monsters (Slimes, Mana Rabbits). Abundant basic herbs.
- **The Verdant Canopy (Deep Forest):** Dense woods blocking sunlight. C and B rank monsters. Treants, Dire Wolves, and hidden Elven ruins.
- **The Scorched Badlands:** High-temperature deserts. Fire-elemental monsters, Golems, and Wyverns. Requires water resources to survive.
- **The Abyssal Tundra:** Freezing wastelands. Home to Ice Trolls and Ancient Liches. High danger level, extreme cold debuffs.
- **The Corrupted Deadlands:** End-game biomes spawned by Calamities. The sky is dark, and undead roam freely.

## 3. Naturally Running Kingdoms
The game features fully simulated kingdoms. They do not just wait for the player; they act independently.

- **Economy:** Merchants travel between cities. If a trade route is blocked by monsters, the price of goods in the connected cities will skyrocket.
- **Politics:** Kings, Nobles, and Factions vie for power. The AI can generate an event where a civil war breaks out.
- **NPC Daily Lives:** NPCs have routines (farming, blacksmithing, sleeping). 
- **Dynamic Expansion:** If a Kingdom prospers (perhaps aided by the player clearing out nearby monster nests), they will expand their borders, build new outposts, and increase their military strength. Conversely, they can be destroyed by Calamity events if left undefended.
