# Character loadout exceptions and regression register

Updated October 13, 2026 after Alex's playtest. This is a coverage register, not a claim that every interaction works. Installed Windows build is v2; v3 adds Maggy Yum Heart removal but has not been installed or natively accepted.

## Inventory rerolls — not yet accepted

- **D4:** inventory rerolls can replace Isaac's passive Mom's Knife and Soy Milk. No native test evidence. Current preset does not intercept D4 or immediately restore the required passives. Fresh run / Twisted reset re-applies the selected kit; that is not reroll immunity.
- **Missing No.:** floor-start inventory rerolls can replace required passives. No native test evidence, including ordering relative to floor callbacks and Continue.
- **D100 / D Infinity's D4 effect / 1- and 6-pip dice rooms:** inventory-reroll variants requiring the same acceptance, including any floor/room effects. Untested.
- **Genesis:** inventory rebuild and starting-kit interactions untested; test its own lifecycle, not assume it is a D4 callback.
- **D6 / Eternal D6:** pedestal rerolls, not inventory rerolls. Verify they cannot bypass Clicker exclusions or collected-item chain exclusions; this is separate from retaining equipped Knife/Soy Milk.
- **Tainted Eden / other forced character or inventory transformations:** separate character-specific acceptance required. Do not infer protection from Isaac tests.

Recommended policy, NOT implemented: preserve character-defining passive/custom mechanics across inventory rerolls, while letting acquired extras reroll normally. Do not broadly regrant the entire kit every frame: that could prevent legitimate active swaps and turn removed pickups into new grants. Active-item replacement policy remains separate. No new item bans have been approved or applied.

### Native acceptance sequence to add

1. Verify installed version and fresh Hard Isaac: D6 105, Knife 114, Soy Milk 330, plus an acquired ordinary passive; record counts/stats/seed/health before testing.
2. Obtain and use an actual D4. Read back required passives, acquired extras, stats and visual attack; test a second use. Do not substitute direct item removal for the real effect.
3. Separately obtain actual Missing No. and take genuine floor transitions (at least two); check after reroll settles, then cold Continue.
4. Run independent D100, D Infinity, dice-room and Genesis cases. Log callback ordering and distinguish actual engine effects from fixture setup.
5. After each case, Twisted reset and verify required kit, old acquired-item exclusions and persistent chain checks. No duplicate required copies.
6. Repeat for custom items on Samson/Eve/Maggy and character-transform cases; do not assume one character covers all.

Use Black Candle only for non-health-sensitive fixtures, recording its black-heart grant. Never alter Alex's active playtest to run these tests.

## Existing exclusions

**Clicker:** blocked in pools, pedestal selection/replacement, direct grant/use and held inventory. Targeted mock/native evidence exists; exhaustive alternate pickup paths are not certified. D4/Missing No. are NOT currently banned.

## User-reported regressions and corrections

- **Samson: Dog Food HP-up → hit grants damage:** user-reported failure; same-update HP-up mock passes, counter-first/red-loss-later mock fails. Native root cause unconfirmed; no fix shipped.
- **Eve: bird stationary:** user-reported failure. Earlier native pursuit fix exists in v2/v3, but the exact build used for the report was not verified. Requested movement should resemble vanilla Dead Bird, targeting the player. Do not dismiss the report as fixed.
- **Maggy: active items unusable:** RETRACTED by Alex; controls misunderstanding. Battery charging requires separate readback, not inferred from that correction.
- **Maggy: Yum Heart removal:** requested and implemented in v3 source/package; retained pocket Yuck. Mock restoration checks pass, no new native acceptance.
- **Maggy: Yuck conversion:** target clarified as conversion without healing/filling empty health; detailed heart-type acceptance remains open. Earlier black-heart/animation observations are recorded, not proof of the final desired behavior.
- **Judas: active card survives Twisted reset:** prior native failure remains open.
- **Duplicate starting copies:** ownership-gated restoration can collapse copies to one; source characterization, native case not certified.
- **Beast/Dogma:** finale crash unresolved; testing deferred by Alex, not fixed.
- **Sprites:** thicker outlines and cleaner in-game pixel readability requested; art revision pending.

See FINAL-QA-20261013.md and PLAYTEST-20261012.md for prior evidence. New checks must be recorded here as mock, native scripted, user-observed or organic acceptance, with build version and limits.
