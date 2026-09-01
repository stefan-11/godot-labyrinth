# Fog of war

`FogOfWarTileMapLayer` (script: `fog_of_war_tile_map_layer.gd`) implements line-of-sight-based fog-of-war on top of the maze. Unlike the base lighting setup (see [Architecture](architecture.md#lighting-and-fog-of-war)), which only controls what's *lit*, this system controls what's *ever been seen* — a room across a wall stays hidden even if it falls within the player's light radius, and once a tile has been seen it stays revealed permanently (map-memory style; it does not re-fog when the player walks away).

## Initialization

On `_ready()`, the layer clears any existing tile data and repaints itself fully black across `WallsTileMapLayer.get_used_rect()` — the bounding rectangle of the maze's painted cells — so the whole maze starts fogged regardless of what (if anything) was hand-painted in the editor. Each wall-layer cell coordinate is converted through world space before being mapped onto a fog-layer cell, since the two `TileMapLayer`s don't share the same local origin (`WallsTileMapLayer.position = Vector2(-1, 0)` vs. `FogOfWarTileMapLayer` at identity).

## Reveal logic

On every physics frame where the player has crossed into a new tile (tracked via `_last_player_tile`, to avoid rescanning every frame), the script:

1. Unconditionally reveals the player's current tile and its 4 orthogonal neighbors (avoids self-occlusion edge cases at tile boundaries).
2. Scans a square neighborhood of `vision_radius_tiles` (default `10`) around the player, filtered to a circle (`dx*dx + dy*dy <= r*r`).
3. For each candidate tile still fogged, casts a physics ray (`PhysicsDirectSpaceState2D.intersect_ray`) from the player's position to the tile's center, against collision layer `1` — the same layer `WallsTileMapLayer`'s wall tiles use for collision. If the ray is unobstructed, the tile is revealed (`erase_cell`).

`vision_radius_tiles` is tunable in the Inspector; it's independent of the `PointLight2D` torch's visual falloff, so adjust it by eye to roughly match. (An earlier idea to derive it automatically from the torch's `PointLight2D` texture/scale was tried and dropped — the light's visually "faded out" edge also depends on blend mode and the `CanvasModulate` ambient level, which can't be reverse-engineered precisely from the texture alone, so manual tuning is simpler and just as effective.)

## Startup physics warmup

The very first reveal — at the player's spawn position — used to ignore walls entirely, even though every reveal after the player moved worked correctly. The cause: `_reveal_around()`'s first call fires on the first `_physics_process()` tick right after `_ready()` (via the `_last_player_tile` sentinel), but `PhysicsDirectSpaceState2D.intersect_ray()` only reflects collision shapes as of the *last completed* physics step. `WallsTileMapLayer`'s tile collision shapes are built during scene instantiation but aren't guaranteed to be registered with the physics server's broadphase until at least one full physics frame has elapsed — so a raycast fired on that very first tick can miss the walls entirely and report every tile as unobstructed, regardless of actual geometry. By the next tile-crossing reveal, the physics server has caught up, which is why the bug only ever showed up once, at startup.

The fix is a short warmup: `_physics_process()` counts `PHYSICS_WARMUP_FRAMES` (`2`) physics ticks via `_physics_frames_elapsed` and returns early without touching `_last_player_tile`/`_reveal_around()` until the warmup has elapsed, so the first raycast-based reveal is deferred by two physics frames (~33ms at 60Hz — imperceptible). `_initialize_fog()` is unaffected and still paints the whole maze black immediately in `_ready()`, since it does no raycasting; only the *reveal* is delayed. If a bug like this resurfaces on a slower machine or after other physics-heavy nodes are added to the scene, bump `PHYSICS_WARMUP_FRAMES` up — it's cheap either way.

## Known limitation

Line-of-sight is checked center-to-center per tile, which can leave small unrevealed slivers at diagonal wall corners. A follow-up improvement would sample a tile's 4 corners instead and reveal it if any corner has a clear line of sight.
