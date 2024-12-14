const std = @import("std");
const bytecode = @import("bytecode.zig");

pub fn compile(allocator: std.mem.Allocator, opps: []bytecode.BytecodeOp, filename: []u8) !void {
	// because zig fucking sucks at that.
	const filename_c = try std.mem.concat(allocator, u8, []const []const u8{filename, ".c"});
	const file = try std.fs.cwd().createFile(filename_c, .{});

	defer file.close();
	defer allocator.free(filename_c);

	var writer = file.writer();

	for (0..opps.len) |i| {
		switch (opps[i].typ) {
			else => continue,
		}
	}
}
