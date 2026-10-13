# Twisted R Key — Hard-chain playtest

An Isaac Repentance+ mod: defeat completion bosses, use the dropped Twisted R Key to return to Basement I, lose acquired items, and restore your character's starting kit. Lost held items remain excluded from the pool for that living chain.

## Current rules

- Eleven checks in one living **Hard Mode** character chain: Mom's Heart/It Lives, Isaac, Satan, Boss Rush, ???, Lamb, Mega Satan, Hush, Delirium, Mother and Beast.
- Dogma is part of the Beast route, not a separate check. Greed modes excluded.
- Black pause-screen checks supplement existing vanilla completion marks. Chain checks survive Twisted resets and continue; death or a fresh run clears them.
- Permanent character-menu badge requires all eleven in the same Hard chain and at least one Twisted reset. Its complete in-game visual flow still needs verification.
- **Beast must be last.** Entering Home before the other ten checks triggers a Twisted reset before the arena; it grants no Beast check.
- Mom's Heart/It Lives retains the reward, allowing early bad-run resets at the cost of fewer items in the pool.
- Samson keeps Bloody Lust. Panic Needle subtracts twice the corresponding red-hit gain, capped per floor; ordinary damage-ups still work.

New collectibles: Unlucky Foot, Panic Needle, Cursed Bow, Undead Bird and Forced Resurrection. Saved character drafts are bundled; implementation/test coverage varies.

## Install

1. Use **Repentance+ with REPENTOGON** for the completion callbacks/overlay and stat hooks this playtest uses. Tested: Repentance+ 1.9.7.12 / REPENTOGON 1.1.3.
2. Extract the `TwistedRKey` folder into the game's `mods` directory (Steam → Manage → Browse local files). Replace an older copy; do not enable duplicate copies.
3. Enable the mod and start a fresh Hard run. Existing saves should be backed up first.

See [PLAYTEST-20261012.md](PLAYTEST-20261012.md) for actual passes and limitations. **All boss drops and the Mega Satan → Delirium portal are not yet physically certified.** Timer reset and exhaustive pickup-history pool exclusion remain unfinished. Older prototype character descriptions are not verification claims.

Isaac normally starts with D6. The optional Knife + Soy Milk preset is selected with `lua TRKLoadout('knife')`; normal default with `lua TRKLoadout('normal')`.

## Development

Runtime: `main.lua`, `content/`, `scripts/`, `resources/`, `metadata.xml`.
`tests/` and `art/` are source-only and excluded from the runtime ZIP.
The rejected Beast arena experiment is retained only for development, never loaded by `main.lua`.

MIT license.
