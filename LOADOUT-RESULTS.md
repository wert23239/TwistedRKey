# Isaac loadout build — Oct 12, 2026

Windows Repentance+ v1.9.7.17, local Dead God slot 3.

- PASS fresh default Isaac: D6=1, Knife=0, Soy=0.
- PASS opt-in selection persists across a cold process launch and fresh run:
  D6=1, Knife=1, Soy=1.
- PASS actual Twisted-key use in knife mode: Basement I, key733 and test Sad
  Onion removed; D6=1, Knife=1, Soy=1 after reset.
- PASS actual Twisted-key use in normal mode: D6=1, Knife=0, Soy=0;
  prior Knife, Soy Milk, Sad Onion, and key removed.
- Fresh patched-process log contained no callback errors.
- Runtime bug found/fixed: synchronous stage reset grants D6 before the engine
  processes MC_USE_ITEM Remove=true. That flag removed the newly restored D6.
  The key now consumes itself explicitly and returns Remove=false,
  Discharge=false, preserving the replacement active.
- `luamod` kept cached required modules. A cold restart was required to test
  the corrected key module; older hot-reload attempts were FAIL, not passes.
- Unknown `trk` console commands were not dispatched on this install. Use
  verified built-in `lua TRKLoadout('knife'/'normal'/'apply'/'status')` helpers.
- Lua API checks: parsing, presets, deduplicated grants, Continue untouched,
  save mode, boss data preservation, non-Isaac dispatch, and callback removal
  regression passed. Planner browser checks including stale-design badges pass.

Original user run was saved before testing. Backup:
`C:\Users\perfe\IsaacLoadoutBackup-20261012-1908`.
After tests, gamestate3 and persistentgamedata3 were restored hash-matching the
post-save backup (`settings-and-saves/Binding of Isaac Repentance+`); slots 1/2
unchanged. Original mod data restored, so default normal mode remains. New code
retained; test log preserved as `loadout-passed.log` in the backup.

Screenshot: Mission Control `assets/isaac/isaac-knife-soy-tested.jpg`.
Unlucky Foot image is an ART DRAFT only, not installed or game-tested.
Magdalene forced-use timing awaits clarification; Cain mechanics are not yet
implemented. No claim of revised all-character mod completion.
