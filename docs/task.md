# Rayaman - Master Development Checklist

This master checklist is designed to guide the development of the game piece by piece (pare by pare). You must complete a section before moving to the next phase to ensure the game evolves stably.

---

## 🏗️ Phase 1: Core Foundation & Basic Survival (The Engine)
*Goal: Ensure the player can move, attack, break tools, collect loot, and fight basic enemies before adding any complex AI.*

### 1.1 Player & UI Setup
- `[ ]` Add `health` (float) and `max_health` (float) to `Player.gd`.
- `[ ]` Add `mana` (float) and `max_mana` (float) to `Player.gd`.
- `[ ]` Add `stamina` (float) and `max_stamina` (float) to `Player.gd`.
- `[ ]` Add `experience` (int) and `level` (int) variables.
- `[ ]` Create `scenes/UI/HUD.tscn`.
- `[ ]` Implement Health Bar UI component.
- `[ ]` Implement Mana Bar UI component.
- `[ ]` Implement Stamina Bar UI component.
- `[ ]` Connect Player stat change signals to HUD bars.

### 1.2 Durability & Gathering Mechanics
- `[ ]` Open `scripts/Inventory&Weapon Sys/itemRes.gd`. Add `max_durability`, `current_durability`, and `is_breakable` exports.
- `[ ]` Open `scripts/Inventory&Weapon Sys/weaponRes.gd`. Inherit the durability variables.
- `[ ]` Create a function `decrease_durability(amount)` in the resources.
- `[ ]` Modify `Player.gd` `attack_sys` to call `decrease_durability` upon swinging.
- `[ ]` Add visual UI feedback when an item breaks (e.g., shatter sound, remove from hand).
- `[ ]` **Add Item:** `Basic Wood Axe` (Resource extending itemRes, low durability).
- `[ ]` **Add Item:** `Basic Pickaxe` (Resource extending itemRes, low durability).
- `[ ]` **Add Item:** `Basic Sickle` (Resource extending itemRes, low durability).
- `[ ]` **Add Item:** `Minor Health Potion` (Restores 25 HP).
- `[ ]` **Add Item:** `Minor Mana Potion` (Restores 25 MP).
- `[ ]` **Add Material:** `Wood Log` (Dropped from trees).
- `[ ]` **Add Material:** `Stone` (Dropped from rocks).

### 1.3 Static Level & First Enemies
- `[ ]` Create `scenes/Levels/WhisperingPlains_Static.tscn` (A flat testing ground for combat).
- `[ ]` Create `scripts/Entitys/base_entity.gd` (Base class for all monsters. Must include Health, Aggro Radius, and state machine: Idle/Wander/Chase).
- `[ ]` **Add Mob (F-Rank):** `Slime`.
  - `[ ]` Implement jump attack logic.
  - `[ ]` Setup Loot Table: `Slime Gel` (70%), `Minor Health Potion` (5%).
- `[ ]` **Add Mob (F-Rank):** `Mana Rabbit`.
  - `[ ]` Implement flee logic (runs away when player approaches).
  - `[ ]` Setup Loot Table: `Meat` (50%), `Mana Shard` (20%).
- `[ ]` **Add Mob (F-Rank):** `Goblin Scavenger`.
  - `[ ]` Implement basic melee swing logic.
  - `[ ]` Setup Loot Table: `Rusted Knife` (10%), `Coarse Cloth` (40%).

*✅ Stop Check: Can the player load in, chop a tree, break their axe, kill a Slime, loot gel, and heal with a potion? If yes, proceed to Phase 2.*

---

## ⚔️ Phase 2: The RPG System & Awakening Weapons
*Goal: Introduce classes, skills, and the unique custom leveling weapons.*

### 2.1 Classes & Skills
- `[ ]` Create `scenes/UI/CharacterSheet.tscn` (Displays Stats, Level, Rank F-SSS, and Class).
- `[ ]` Implement Class System base logic.
- `[ ]` **Add Class:** `Tank`. Implement `Taunt` skill (Forces all enemies in radius to target player).
- `[ ]` **Add Class:** `DPS`. Implement `Dash/Backstab` skill (Bonus damage if hitting enemy from behind).
- `[ ]` **Add Class:** `Support`. Implement `Self-Heal` skill (Converts MP to HP over time).

### 2.2 Standard Weapons vs Awakening Weapons
- `[ ]` **Add Weapon:** `Rusted Sword` (Common, breaks easily).
- `[ ]` **Add Weapon:** `Wooden Bow` (Common, requires arrows).
- `[ ]` **Add Weapon:** `Novice Staff` (Common, low magic damage).
- `[ ]` Create `scripts/Inventory&Weapon Sys/awakeningWeaponRes.gd` (Inherits weaponRes, disables breaking).
- `[ ]` Add variables to Awakening Weapon: `weapon_xp`, `weapon_level`, `weapon_rank`.
- `[ ]` **Add Awakening Weapon:** `BloodHound` (Sword).
  - `[ ]` Implement Rank F: Base damage.
  - `[ ]` Implement Rank E unlock: 5% Lifesteal.
  - `[ ]` Implement Rank D unlock: Bleed effect on hit.
- `[ ]` **Add Awakening Weapon:** `Starfall` (Staff).
  - `[ ]` Implement Rank F: Small magic projectile.
  - `[ ]` Implement Rank E unlock: Projectiles pierce 1 enemy.

### 2.3 Tier 2 Enemies (E-Rank)
- `[ ]` **Add Mob (E-Rank):** `Dire Wolf`.
  - `[ ]` Implement pack behavior (calls nearby wolves when aggroed).
  - `[ ]` Loot Table: `Wolf Pelt`, `Sharp Fang`.
- `[ ]` **Add Mob (E-Rank):** `Iron Tusk Boar`.
  - `[ ]` Implement charge attack (high damage, moves in straight line).
  - `[ ]` Loot Table: `Boar Tusk`, `Quality Meat`.
- `[ ]` **Add Mob (E-Rank):** `Crystal Stag` (Neutral, flees but has high HP).

*✅ Stop Check: Is BloodHound leveling up when you kill Dire Wolves? Can you use your class skill? If yes, proceed to Phase 3.*

---

## 🧠 Phase 3: AI Story Director V1 & Danger Level
*Goal: Make the world hostile and reactive. Enemies should spawn based on how long the player stays in one place and their current rank.*

### 3.1 The Danger Director
- `[ ]` Create Autoload Singleton: `scripts/utils/ai_director.gd`.
- `[ ]` Add `world_danger_level` (float) that slowly ticks up over time.
- `[ ]` Add UI element: A small skull or colored orb in the corner (Green = Safe, Yellow = Caution, Red = Danger, Purple = Calamity).
- `[ ]` Implement Spawner Logic in AI Director:
  - `[ ]` If Danger is Low: Spawn F and E rank mobs.
  - `[ ]` If Danger is Medium: Spawn D and C rank mobs.
  - `[ ]` If player has stayed in the same chunk for >10 minutes, trigger "Ambush Event" (spawns 3-5 hostile mobs instantly around the player).

### 3.2 Mid-Tier Mobs (D & C Rank)
- `[ ]` **Add Mob (D-Rank):** `Werewolf`.
  - `[ ]` Spawns only at night (Requires basic day/night cycle integration).
  - `[ ]` Has fast HP regeneration.
- `[ ]` **Add Mob (D-Rank):** `Stone Golem` (Neutral until hit, high physical defense).
- `[ ]` **Add Mob (C-Rank):** `Orc Berserker` (High damage, acts as tank for other mobs).
- `[ ]` **Add Mob (C-Rank):** `Treant` (Disguised as a tree, attacks if player chops nearby).
- `[ ]` **Add Mob (C-Rank Trap):** `Mimic Chest`.
  - `[ ]` Disguises as a loot chest. If player interacts, it bites for 50% max HP.

*✅ Stop Check: If you stand still for 15 minutes, does the Danger level turn Red and do Orcs/Werewolves spawn to kill you? If yes, proceed to Phase 4.*

---

## 🌍 Phase 4: Procedural Generation & Kingdoms
*Goal: Connect the C# procedural generation to create an infinite, playable world.*

### 4.1 World Generation Linking
- `[ ]` Modify `scenes/GameWorld.cs` to use `biome.cs` to generate the terrain mesh/tilemap.
- `[ ]` Implement chunk loading/unloading based on player position.
- `[ ]` Setup Biome: `Whispering Plains` (Flat, grass tiles, spawns Slimes/Boars).
- `[ ]` Setup Biome: `Verdant Canopy / Forest` (Dense trees, spawns Wolves/Treants).
- `[ ]` Setup Biome: `Scorched Badlands` (Rocky, spawns Golems, high ore density).
- `[ ]` Tie resource node spawners (Trees, Ores, Herbs) to procedural chunk generation.

### 4.2 Kingdom Hubs
- `[ ]` Create `scenes/Levels/KingdomVillage_Template.tscn`.
- `[ ]` Implement logic to spawn one Kingdom chunk near the player's starting coordinates (0,0).
- `[ ]` Create NPC Script: `villager.gd` (Wanders around).
- `[ ]` Create NPC Script: `merchant.gd` (Has an inventory UI where player can buy/sell).
- `[ ]` **Add Item:** `Town Portal Scroll` (Teleports player back to the Kingdom).

### 4.3 High-Tier Mobs (B & A Rank)
- `[ ]` **Add Mob (B-Rank):** `Wyvern` (Flies, shoots fireballs, dodges melee).
- `[ ]` **Add Mob (A-Rank):** `Shadow Clone`.
  - `[ ]` Copies player's exact stats, class, and weapons upon spawning.
  - `[ ]` Extremely rare spawn triggered by AI Director when Danger is very high.

*✅ Stop Check: Can you walk for 5 minutes in one direction, transitioning from Plains to Forest, and find a generated merchant to sell your loot? If yes, proceed to Phase 5.*

---

## 🔁 Phase 5: Deus Ex Machina & The Returner System
*Goal: Add the Isekai/Manhwa story tropes.*

### 5.1 The Savior Event
- `[ ]` Create `scenes/Entitys/Savior_NPC.tscn` (e.g., Princess Elara).
- `[ ]` Give Savior NPC maxed out stats and an SSS-Rank weapon.
- `[ ]` In `ai_director.gd`, monitor player HP during combat.
- `[ ]` If HP < 10% and player is fighting an enemy C-Rank or higher:
  - `[ ]` Pause player movement.
  - `[ ]` Spawn Savior NPC falling from the sky.
  - `[ ]` Savior executes a massive AoE attack, killing all enemies.
  - `[ ]` Savior drops a `Supreme Health Potion` and despawns.
  - `[ ]` Set a cooldown flag so this event cannot happen again for 2 hours.

### 5.2 Calamities and Regression
- `[ ]` Create `scripts/utils/save_manager.gd` (Saves player level, inventory, and Awakening Weapon data to JSON).
- `[ ]` **Add Calamity Mob (SSS-Rank):** `Demon Lord` or `Abyssal Dragon`.
- `[ ]` Trigger Calamity Event: When Danger Level maxes out (Purple), spawn the Boss in the world. Change sky color.
- `[ ]` Implement **The Returner System**:
  - `[ ]` If player dies to the Calamity, intercept the Game Over screen.
  - `[ ]` Play a "Regression" cutscene/animation.
  - `[ ]` Reset Player Level to 1.
  - `[ ]` Empty standard inventory (lose all normal swords, potions, wood).
  - `[ ]` Retain the `Awakening Weapon` (e.g., BloodHound) at its current high rank.
  - `[ ]` Grant 1 permanent Regression Perk (e.g., "Foresight: +10% Dodge Chance").
  - `[ ]` Save the game and respawn player at the Kingdom Hub.

*✅ Stop Check: Try to fight the Calamity and die. Do you wake up at level 1 but still have your overpowered BloodHound sword? If yes, proceed to Phase 6.*

---

## 🏰 Phase 6: Guilds & End-game Loop
*Goal: The infinite endgame loop.*

- `[ ]` Create Guild Hall building in the Kingdom.
- `[ ]` Create Guild Management UI (Roster, Vault, Dispatch Map).
- `[ ]` Implement Recruitment: Pay gold to hire procedurally generated NPCs (Rank F to A).
- `[ ]` Implement Dispatch system: Send NPCs to Biomes for 30 real-time minutes to lower the `Danger Level` in that region and bring back loot.
