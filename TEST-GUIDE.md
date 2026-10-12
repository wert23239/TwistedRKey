# Twisted R Key — quick test guide

Use the spare test save (slot 3). Start a run as Isaac with the mod enabled.
Open the debug console with the grave/tilde key (`/~); press Enter after each command, then close the console with the same key or Esc. If it does not open, close Isaac and set EnableDebugConsole=1 in the Repentance+ options.ini (use savedatapath.txt in the game folder to locate the actual save path), then relaunch with a mod enabled.

## 1. Sprite / pickup

```text
spawn 5.100.733
```

733 was Twisted R Key's ID in the tested install. Check the pedestal shows the purple-swirl R key, pick it up, and check its held-item HUD icon too. Report which is missing: pedestal, HUD, or both.
If the ID changes with other mods, use this instead:

```text
lua Isaac.ExecuteCommand("spawn 5.100." .. Isaac.GetItemIdByName("Twisted R Key"))
```

## 2. Reset / inventory

```text
stage 11
g c1
g t1
g c733
```

This puts you in the Dark Room, adds Sad Onion and Swallowed Penny, then grants the key directly (so this is NOT a pickup/sprite test). Close the console and press Space to use the key.
Check: Basement I, Sad Onion gone, trinket gone, key consumed; record whether the timer resets and what starting items remain. Keyboard Space assumes default controls.

CURRENT BUILD: Knife + Soy Milk after reset is expected prototype behavior. TARGET DEFAULT: Isaac's D6. Knife + Soy Milk should become a separate optional mode; no mode toggle exists yet. Timer reset, item exclusion, Clicker ban and character-specific deathless completion tracking are not implemented yet.

## 3. Actual boss reward / persistence

For a quick Lamb route, use stage 11, navigate to the real boss room, and defeat The Lamb. Avoid arbitrary room-index teleports. Check one key reward appears, pick it up without touching the ending chest, then use it. Check boss progress survives reset, then exit normally and Continue to check persistence. The current tracker is a prototype global boss checklist, not the planned per-character deathless marks.

## Report format

Character / boss / command used / expected / actual. For sprite issues, specify pedestal vs HUD vs both. Steam F12 screenshots are useful; they captured the real game reliably when remote-desktop images were stale.

## Isaac selectable preset (loadout build)

Normal Isaac is now the default, with D6 restored after a Twisted reset.
Use the console to select extras independently of the web planner:

```text
lua TRKLoadout('normal')
lua TRKLoadout('knife')
lua TRKLoadout('apply')
lua TRKLoadout('status')
```

Choose either `normal` or `knife`, not both. The selection is saved for fresh
runs and Twisted resets. `apply` is a testing helper that grants the selected
preset without removing acquired items. `normal` does not remove extras from
an already-running inventory; test it on a fresh run or a Twisted reset.
`knife` means D6 + Mom's Knife + Soy Milk. No custom collectible is needed.

To test reset, grant Sad Onion and the Twisted key by its current resolved ID,
use the key, then run `lua TRKLoadout('status')`. Expect D6=1, Knife=1, Soy=1 in
knife mode, or D6=1, Knife=0, Soy=0 in normal mode; Sad Onion should be gone.
The numeric custom key ID can change when other mods are installed.

Build/test markers in Mission Control are separate from draft saves. Any
saved design change flags earlier results for review; art previews alone do
not count as an in-game test.
