# Architecture

The entire game currently lives in a single scene, `level01.tscn` (configured as the project's `run/main_scene`).

## Scene composition

`level01.tscn` is made up of the following nodes:

- **`WallsTileMapLayer`** — a `TileMapLayer` built from `maze_tileset.png`, painted with a `TileSet` that defines a `Wand` (wall) terrain. This is the maze geometry and its collision layer.
- **`FogOfWarTileMapLayer`** (script: `fog_of_war_tile_map_layer.gd`) — a second `TileMapLayer`, using `black_tile_32x32.png`, layered on top of the maze to implement line-of-sight fog-of-war. See [Fog of war](fog-of-war.md) for details.
- **`CanvasModulate`** — darkens the entire canvas globally. Combined with the `PointLight2D` nodes below, this is what produces the lantern effect: the scene is only visible where a 2D light punches through the global darkness.
- **`CharacterBody2D`** (script: `character_body_2d.gd`) — the player character, with the following children:
  - `CollisionShape2D` — physics collision against the walls layer.
  - `Sprite2D` — the player's visual.
  - `Camera2D` — follows the player.
  - `PointLight2D` — the player's personal light source ("torch"), with `shadow_enabled = true` so walls occlude light.
- **`PointLight2D2`** — a second, static light placed in the maze independent of the player, illuminating a fixed area.

## Player movement

`character_body_2d.gd` drives the player:

- Reads input via `Input.get_vector("left", "right", "up", "down")`.
- Sets `velocity` from that direction times an `@export var speed` (defaults to `300.0`, currently overridden to `500.0` on the node in `level01.tscn`).
- Calls `move_and_slide()` each physics frame.

Input actions (`up`, `down`, `left`, `right`) are defined in `project.godot` under `[input]`, currently bound to the arrow keys.

## Lighting and fog-of-war

What's *lit* is still driven purely by Godot's built-in 2D lighting system:

1. `CanvasModulate` darkening everything by default.
2. `PointLight2D` nodes (on the player, and the standalone `PointLight2D2`) lighting up the areas around them.
3. `shadow_enabled` on those lights, so `WallsTileMapLayer` occludes light and casts shadows.

What's *ever been seen* is tracked separately by `FogOfWarTileMapLayer`, which permanently reveals tiles as the player gets line-of-sight to them via raycasting — independent of the lighting above and of Godot's light-occlusion system. See [Fog of war](fog-of-war.md) for the full mechanism.

## Editing the maze

The maze layout and collision are stored as tile map data (a packed byte array) directly inside `level01.tscn`. This is normally painted using the Godot editor's TileMap tool rather than hand-edited as text — the `.tscn` format is human-readable but contains generated UIDs, sub-resource references, and packed binary data that are error-prone to edit by hand.
