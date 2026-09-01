# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Labyrinth is a 2D top-down maze game built with **Godot 4.7** (Mobile rendering method, Jolt physics for 3D). There is no external build system, package manager, or test suite — the project is developed and run through the Godot editor / `godot` CLI binary.

## Common commands

Godot is normally driven through the editor GUI, but the same operations are available headlessly via the `godot` CLI binary (Godot 4.7+ must be installed and on `PATH`):

```bash
# Open the project in the editor
godot -e --path .

# Run the game (executes the scene set as run/main_scene in project.godot)
godot --path .

# Run headless (e.g. for CI / quick script checks, no window)
godot --headless --path .

# Check the project for script errors without running it
godot --headless --check-only --path .
```

There are no linters, formatters, or automated tests configured in this repo.

## Architecture

The entire game currently lives in a single scene, `level01.tscn` (the project's `run/main_scene`), composed of:

- **`WallsTileMapLayer`** — a `TileMapLayer` built from `maze_tileset.png`, painted with a `TileSet` that defines a `Wand` (wall) terrain. This is the maze geometry and collision layer.
- **`FogUnknownLayer`** — a second `TileMapLayer`, using `black_tile_32x32.png`, layered over the maze to implement fog-of-war (areas the player hasn't explored/lit yet appear as black tiles).
- **`CanvasModulate`** — darkens the whole canvas globally, so the scene is only visible where `PointLight2D` nodes cast light. This is what makes the fog-of-war / lantern effect work (2D lights punch through the global darkness).
- **`CharacterBody2D`** (script: `character_body_2d.gd`) — the player. Movement is driven by `Input.get_vector("left", "right", "up", "down")` and `move_and_slide()`, with `speed` exposed as an `@export` var. It carries its own child nodes:
  - `CollisionShape2D` for physics collision against the walls layer.
  - `Sprite2D` for the player's visual.
  - `Camera2D` that follows the player.
  - `PointLight2D` — the player's personal light source (their "torch"), with shadows enabled so walls occlude light.
- A standalone **`PointLight2D2`** — a second, static light placed in the maze (e.g. to illuminate a fixed area independent of the player).

Input actions (`up`, `down`, `left`, `right`) are defined in `project.godot` under `[input]` and are currently bound to the arrow keys.

Key gameplay logic to know when extending this project:
- Player movement/physics: `character_body_2d.gd`.
- Maze layout and collision: edited via the `WallsTileMapLayer` tile map data in `level01.tscn` (normally painted in the Godot editor's TileMap tool rather than hand-edited as text).
- Visibility/fog-of-war and lighting are achieved purely through Godot's 2D lighting system (`CanvasModulate` + `PointLight2D` + `shadow_enabled`), not custom shader or scripted fog logic — there is currently no script that reveals/hides `FogUnknownLayer` tiles based on player position.

## Notes

- `.tscn`/`.tres`/`project.godot` files are Godot's text-based resource format; prefer editing them through the Godot editor when possible, since they contain generated UIDs, sub-resource references, and packed binary tilemap data (`PackedByteArray`) that are error-prone to hand-edit.
- The `.godot/` directory is engine-generated cache/import data (git-ignored) and should never be edited directly.
