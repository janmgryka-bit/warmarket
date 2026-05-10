# War Market - Project Direction

War Market is a Godot 4.6.2 stylized historical auto-battler prototype. The current priority is to stabilize the core loop and project direction before adding more gameplay systems.

## Confirmed Core Direction

War Market should be primarily a PvP-style auto-battler.

- Main rounds use PvP ghost/opponent snapshot armies.
- Opponent snapshots, mirror army data, battle payloads, and battle history are core loop foundations.
- Neutral creep/minion rounds happen occasionally for gold, items, and economy pacing.
- `enemy_wave_database.gd` may be used for neutral rounds.
- Hand-authored enemy waves are not the main progression path.

## Explicit Non-Goals

- Do not turn War Market into an authored enemy campaign progression game.
- Do not make hand-authored waves the primary round-to-round loop.
- Do not add new major gameplay systems until the PvP round flow and neutral round structure are clear.
- Do not redesign the current arena, bench, and shop layout while stabilizing core gameplay.

## Current Prototype State

The prototype currently has a playable auto-battler foundation:

- 8x8 clickable board.
- Stable arena, visual bench row, and shop layout.
- Bench deploy, sell, reroll, and shop flow.
- Auto battle with HP, damage, range, cooldowns, movement, death, target-facing rotation, floating damage numbers, attack visuals, and death feedback.
- Gold, interest, streak bonus, XP/level, and unit cap.
- Tier 1 and Tier 2 units.
- 1-star, 2-star, and 3-star merging, including deployed plus bench merge cases.
- Faction and role synergies.
- Unit details panel.
- Items v0.
- Player HP, Game Over, Victory, and New Run states.
- Opponent snapshot, Mirror Army, battle payload, battle summary, and battle history foundations.
- AudioManager and mute toggle foundation.
- Unit combat identities.
- Dynamic market prices, softer dynamic market pressure, and basic battlefield morale.

## Art And Cosmetic Direction

The art direction is stylized low-poly with a castle courtyard / war market arena identity. The visual language should favor stone, wood, and brass UI materials, readable silhouettes, and skin-friendly surfaces.

Future monetization should be cosmetic-first:

- Unit skins.
- Arena skins.
- UI skins.
- Seasonal skins.
- Faction skins.

Cosmetics must preserve gameplay clarity, faction/role readability, board occupancy, HP bars, and competitive fairness.

## Technical Structure

`game.gd` is very large and should eventually be split, but not during the current documentation pass. Existing extracted rule/data files include:

- `unit_database.gd`
- `item_database.gd`
- `enemy_wave_database.gd`
- `economy_rules.gd`
- `synergy_rules.gd`
- `battle_snapshot.gd`

## Known Technical Debt

- `game.gd` owns too many responsibilities and will need staged extraction later.
- PvP round flow is not yet a first-class structure.
- Neutral rounds need to be defined as occasional economy/item pacing moments, not campaign progression.
- Battle snapshot data exists, but the full round lifecycle around snapshots needs a clearer v1 implementation.
- Smoke tests should expand as shared rules are extracted from `game.gd`.

## Recommended Next Milestone

### PvP Round Flow v1 + Neutral Creep Rounds

Define and implement the round loop that makes PvP ghost battles the default experience, with occasional neutral creep/minion rounds.

Scope:

- Make normal rounds choose a PvP ghost/opponent snapshot battle payload.
- Add a predictable neutral round cadence for gold/items/economy pacing.
- Use `enemy_wave_database.gd` only for neutral round data.
- Keep authored enemy waves out of the main progression loop.
- Preserve existing shop, bench, battle, economy, merge, synergy, item, morale, and snapshot behavior unless a change is directly required for the round flow.
- Add focused smoke coverage for the new round selection behavior.

Out of scope:

- Campaign progression.
- New unit systems.
- New UI layout.
- Large `game.gd` refactor.
- New monetization systems.

## Future Milestones

- Round history and opponent snapshot polish: make match history clearer and more useful for debugging and player feedback.
- Neutral reward polish: tune gold, item, and pacing rewards after neutral rounds exist.
- `game.gd` staged extraction: move round flow, shop/economy orchestration, battle setup, and UI presentation into focused modules over time.
- Item system v1: deepen item drops, assignment, and combat identity once round flow is stable.
- Content expansion: add more units, factions, roles, and synergies after the loop is stable.
- Art pass: improve low-poly unit silhouettes, arena skin blockouts, UI skin readiness, and combat feedback.
- Audio pass: add SFX and music behavior on top of the current AudioManager foundation.

## Next Codex Task

Implement **PvP Round Flow v1 + Neutral Creep Rounds**.

The task should keep War Market primarily PvP/ghost snapshot based, use neutral rounds only for occasional gold/items/economy pacing, and avoid turning `enemy_wave_database.gd` into the main campaign progression system.
