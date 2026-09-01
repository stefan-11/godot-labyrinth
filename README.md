# Labyrinth

A 2D top-down maze game built with [Godot](https://godotengine.org/) 4.7, featuring a fog-of-war / lantern-style lighting effect: the maze is dark except for the area lit by the player's torch.

## Requirements

- [Godot Engine 4.7](https://godotengine.org/download) or later

## Running the project

Open the project in the Godot editor:

```bash
godot -e --path .
```

Or run it directly without opening the editor:

```bash
godot --path .
```

## Controls

| Action | Key |
| --- | --- |
| Move up | Arrow Up |
| Move down | Arrow Down |
| Move left | Arrow Left |
| Move right | Arrow Right |

## Project structure

```
.
├── level01.tscn             # The main (and currently only) scene
├── character_body_2d.gd     # Player movement script
├── maze_tileset.png         # Tileset used for the maze walls/floor
├── black_tile_32x32.png     # Tile used for the fog-of-war layer
├── icon.svg                 # Project icon
└── project.godot            # Godot project configuration (input map, display, etc.)
```

## Documentation

More detailed, topic-specific documentation lives in [`docs/`](docs/):

- [Architecture](docs/architecture.md) — how the scene, maze, and lighting/fog-of-war system fit together

## Development

See [`CLAUDE.md`](CLAUDE.md) for guidance on developing this project with Claude Code, including common commands.
