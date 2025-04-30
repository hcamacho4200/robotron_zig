# zig_robotron
Learning Zig, making a Robotron 2084 clone to learn the language.

# to run
- clone repo

- install zig
```
brew install zig -- requires zig 0.13.0, 0.14.0 is the current version, perform manual installation
```

- clone raylib into the repo:
```
git clone --depth 1 --branch 5.0 https://github.com/raysan5/raylib.git
git clone --depth 1 --branch 4.0 https://github.com/raysan5/raygui.git
```
- build and run
```
zig build run
```

Use the s-d-f-e keys to walk about and the j-k-l-i to shoot.

Very much a work in progress.
