# Run Blackbriar

On this Linux computer, run `builds/blackbriar-linux/play.sh` (or double-click it and choose Run). The folder contains a bundled Godot runtime and packaged game data, so the editor does not need to be open. Keep these files together.

From a terminal:

```sh
./builds/blackbriar-linux/play.sh
```

The bundled runtime is the installed Arch Linux x86_64 build and depends on this system's shared libraries. This is a tested local Linux package, not a universal Linux or Windows release. A portable classroom distribution should be exported with official templates for each target operating system.

To develop, open `project.godot` in Godot 4.7.2 and press F6 on `main.tscn` or F5. To run directly from source:

```sh
godot --path .
```

To rebuild the resource pack after edits:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --export-pack Linux builds/blackbriar-linux/blackbriar.pck
```

To run the engine regression suite:

```sh
godot --headless --path . --script test_runner.gd
```

Progress is stored in Godot's user data directory as `blackbriar_profile.json`, independently of the build folder. Removing or rebuilding the package does not reset progress. No account or network connection is required to play.
