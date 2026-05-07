# Technical Notes

## Testing

Run smoke tests from the repository root:

```bash
./run_tests.sh
```

Avoid large gameplay changes without focused smoke coverage. When adding or refactoring gameplay rules, include tests for the player-facing behavior and persistence paths.

## Asset Organization

- Keep Godot imported/runtime assets under `godot_project/war-market/assets/`.
- Keep source files, references, exports, concepts, and work-in-progress assets under the top-level `assets/` folder.
- Keep general research and external references under `references/`.
- Do not move existing scripts or scenes without updating Godot paths and tests.

## Implementation Notes

- Prefer small, data-driven rules helpers for economy, synergies, snapshots, waves, and item data.
- Keep visual polish separate from combat logic.
- Preserve board coordinates, click signals, and roster persistence when changing presentation.
