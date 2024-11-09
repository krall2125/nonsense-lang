build: src/main.zig
	zig build -Doptimize=ReleaseSafe
	cp ./zig-out/bin/nonsense-zig ./nonsense
