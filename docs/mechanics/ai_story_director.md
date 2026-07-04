# AI Story Director & Mechanics

## 1. The Director Model
The game utilizes a 5-6M parameter AI model to act as the "Dungeon Master". 
- **Inputs:** Player Rank, current Level, time since last level up, current location (biome/kingdom), current health/mana, inventory wealth.
- **Outputs:** Event triggers, weather changes, spawn rate multipliers, plot twists.

## 2. Threat & Danger Level System
The world is not static. The **Danger Level** is a hidden metric that constantly ticks upward.
- **Forced Progression:** Because the Danger Level rises, the player is forced to explore, hunt, and level up. Staying in the "safe" beginner village will eventually result in the village being attacked by higher-tier monsters.
- **Rank Monitoring:** The AI compares the Danger Level to the Player's Rank. If the player is over-leveled, it throws curveballs (e.g., an ambush of Assassins). If the player is under-leveled and stagnating, it spawns a **Calamity Event**.

## 3. Dynamic Events System
The AI selects from a pool of Pre-created Events based on the narrative context.

### Event Type: "The Wake-Up Call"
- **Trigger:** Player is out of the kingdom, wandering the wilderness, and hasn't leveled up in a long time.
- **Action:** The AI spawns a "Monster Demon" or "Mini-Calamity" directly in the player's path.
- **Goal:** Force a high-stakes combat encounter. Fleeing might be the only option if they are too weak.

### Event Type: "Deus Ex Machina / Royal Encounter"
- **Trigger:** Player is on the brink of death in the wilderness (HP < 10%) facing an overwhelming enemy, AND they haven't triggered this event recently.
- **Action:** A powerful, pre-generated NPC (e.g., a Kingdom Prince, Princess, or an S-Rank Adventurer) intervenes, instantly defeating the monster and saving the player.
- **Narrative Impact:** This NPC is logged in the player's relationship tracker. The AI will weave this NPC into future plotlines (e.g., the Princess later asks the player for a favor, or they meet again at the Royal Academy).

### Event Type: "Kingdom Intrigue"
- **Trigger:** Player returns to the city with high-tier loot.
- **Action:** Corrupt nobles try to seize the loot, or a merchant guild offers a shady contract. 
