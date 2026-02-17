# Twisted R Key

A **Binding of Isaac: Repentance** mod that adds a twisted take on R Key — restart the run, but **lose everything**.

## Concept

After defeating an endgame boss, the **Twisted R Key** spawns. Using it teleports you back to Chapter 1, Stage 1 — but **strips all your items**. You restart with only a unique character-specific loadout designed to create interesting and challenging synergies.

Your goal: **defeat every endgame boss** across multiple twisted restarts. Boss kills persist across R Key uses, and new character setups unlock as you progress.

## Character Setups

| Character | Starting Loadout | Notes |
|-----------|-----------------|-------|
| **Isaac** | Mom's Knife + Soy Milk | Classic rapid-fire knife tears |
| **Azazel** | Rock Bottom + random stat up | One big stat locked in |
| **The Lost** | One random flight item | "Grounded" — starts without innate flight |
| **Eden** | Experimental Treatment + Eden's Blessing | One blessing per run, random stats |
| **Jacob & Esau** | Dr. Fetus + My Reflection + No. 2 | Explosive chaos for two |
| **Tainted Isaac** | Sacred Orb ×3 | Inverse Sacred Orb — only bad items appear |
| **Tainted Lost** | Little Baggy + Crystal Ball | Pills-only with planetarium synergy |
| **Tainted Cain** | Mom's Shovel | Items already become pickups via Bag of Crafting |
| **Tainted Keeper** | Magneto + Cursed Penny (trinket) | No shop doors — coins come to you cursed |
| **Tainted Eden** | TM Trainer | Glitched items, one inverse R Key on death |
| **Tainted Jacob** | Birthright | Enhanced Dark Esau synergy |

## Boss Checklist

Track your progress across these endgame bosses:

- [ ] Mom
- [ ] Mom's Heart / It Lives
- [ ] Isaac
- [ ] ???
- [ ] Satan
- [ ] The Lamb
- [ ] Mega Satan
- [ ] Hush
- [ ] Delirium
- [ ] Mother
- [ ] Dogma
- [ ] The Beast

## Installation

### Steam Workshop
Subscribe on the Steam Workshop (link TBD).

### Manual
1. Locate your Isaac mods folder:
   - **Windows:** `C:\Users\<you>\Documents\My Games\Binding of Isaac Repentance\mods\`
   - **macOS:** `~/Library/Application Support/Binding of Isaac Repentance/mods/`
   - **Linux:** `~/.local/share/binding of isaac repentance/mods/`
2. Copy the `TwistedRKey` folder into the mods directory
3. Enable the mod in-game from the Mods menu

## Requirements

- **The Binding of Isaac: Repentance** (or Repentance+)
- **Repentogon** recommended (for enhanced modding API support)

## Development

```bash
# Clone the repo
git clone https://github.com/wert23239/TwistedRKey.git

# Symlink into your mods folder for live development
ln -s "$(pwd)/TwistedRKey" "/path/to/isaac/mods/TwistedRKey"

# The mod auto-loads on game start — use `luamod` console command to hot-reload
```

### File Structure

```
TwistedRKey/
├── metadata.xml              # Mod metadata for Isaac
├── main.lua                  # Entry point — registers mod and loads modules
├── content/
│   └── items.xml             # Custom item definition
├── scripts/
│   ├── twisted_r_key.lua     # Core item mechanic
│   ├── character_setups.lua  # Per-character starting loadouts
│   ├── boss_tracker.lua      # Endgame boss kill tracking
│   └── progression.lua       # Character unlock system
└── resources/                # Sprites and assets (TBD)
```

## License

MIT
