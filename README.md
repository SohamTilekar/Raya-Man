# Rayaman

A procedurally generated, medieval fantasy Action RPG built with **Godot Engine** (C# & GDScript hybrid). 

Inspired by popular Isekai anime and manhwa regression tropes, the game features a dynamic, AI-driven story environment where a background Director manages threat progression and triggers narrative events based on your performance.

---

## 🌟 Key Features

*   **Dynamic AI Story Director:** Uses a lightweight AI model to track player activity, scaling the background threat level and triggering events (like amushing if you stay in one spot too long).
*   **The Returner (Regression) Loop:** If you die to a high-level world Calamity, you regress to level 1 but retain your custom Awakening Weapons and gain permanent perks for the next run.
*   **Awakening Weapons:** Special custom weapons (e.g., *BloodHound*) that bond with the player and level up alongside your Rank, bypassing the normal durability degradation system.
*   **Weapon Durability:** Standard weapons degrade and break based on usage, encouraging strategic resource management and tool replacement.
*   **Procedural World Gen:** Continual chunk loading with multiple biomes (Plains, Forests, Badlands) and integrated simulated kingdoms.
*   **Tank System & Class Archetypes:** Tactical aggro control for Tanks, stealth/critical spikes for DPS, and heal/shield adjustments for Support classes.

---

## 📂 Project Structure

*   `/docs`: Detailed game mechanics, manuals, and planning records.
    *   [`game_overview.md`](docs/plan/game_overview.md) — Main pitch and high-level ideas.
    *   [`ai_story_director.md`](docs/mechanics/ai_story_director.md) — Mechanics of the AI Director and events.
    *   [`progression_and_classes.md`](docs/mechanics/progression_and_classes.md) — The Class roles and Rank hierarchy.
    *   [`mobs_reference.md`](docs/world/mobs_reference.md) — Manual listing peaceful, neutral, and hostile monsters.
    *   [`items_reference.md`](docs/world/items_reference.md) — Weapons, tools, magic element tiers, and rarity structures.
    *   [`dynamic_plot.md`](docs/story/dynamic_plot.md) — Savior events and Calamity/Regression logic.
    *   [`task.md`](docs/task.md) — The master step-by-step checklist to build the game part-by-part.
*   `/scenes`: Godot scene files (`.tscn`).
*   `/scripts`: Game source code split between C# (`.cs`) for backend systems (like generation) and GDScript (`.gd`) for gameplay entities.
*   `/resources`: Configurable custom Godot resources (e.g., inventories, item databases).

---

## 🚀 Getting Started

1. Ensure you have **Godot Engine 4.x (Mono/.NET Edition)** installed.
2. Clone the repository and configure Git LFS if tracking raw assets.
3. Open the project in Godot and build the C# solution (`Rayaman.sln`).
4. Review the development checklist in [`docs/task.md`](docs/task.md) to start implementing features phase-by-phase.
