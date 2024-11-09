const std = @import("std");
const bytecode = @import("bytecode.zig");

pub fn interpret(allocator: std.mem.Allocator, opps: []bytecode.BytecodeOp) !void {
	var i: usize = 0;
	var stack = std.ArrayList(i64).init(allocator);
	var allocation_stack = std.ArrayList([]u8).init(allocator);

	const stdout = std.io.getStdOut().writer();

	while (i >= 0 and i < opps.len) : (i += 1) {
		switch (opps[i].typ) {
			.OP_PUSH => try stack.append(@bitCast(opps[i].params.items[0])),
			.OP_POP => _ = stack.popOrNull() orelse 0,
			.OP_DUP => {
				const val = stack.popOrNull() orelse 0;

				try stack.append(val);
				try stack.append(val);
			},
			.OP_ADD => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(b + a);
			},
			.OP_SUBTR => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(b - a);
			},
			.OP_MULTI => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(b * a);
			},
			.OP_DIV => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(@divExact(b, a));
			},
			.OP_MOD => {
				const a = stack.popOrNull() orelse 0; const b = stack.popOrNull() orelse 0;

				try stack.append(@rem(b, a));
			},
			.OP_PUTC => {
				const a = stack.popOrNull() orelse 0;

				try stdout.print("{c}", .{@as(u8, @truncate(@as(u64, @bitCast(a))))});
			},
			.OP_PUTN => {
				const a = stack.popOrNull() orelse 0;

				try stdout.print("{d}", .{a});
			},
			.OP_JUMP_IF_FALSE => {
				const a = stack.popOrNull() orelse 0;

				if (a == 0) {
					i = opps[i].params.items[0];
				}
			},
			.OP_JUMP => {
				i = opps[i].params.items[0];
			},
			.OP_DEBUG => {
			},
			.OP_EQ => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(@intFromBool(a == b));
			},
			.OP_NOT => {
				const a = stack.popOrNull() orelse 0;

				try stack.append(@intFromBool(a == 0));
			},
			.OP_GT => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(@intFromBool(b > a));
			},
			.OP_LT => {
				const a = stack.popOrNull() orelse 0;
				const b = stack.popOrNull() orelse 0;

				try stack.append(@intFromBool(b < a));
			},
			.OP_MEM => {
				const a = stack.popOrNull() orelse 0;

				if (a <= 0) {
					std.debug.print("Cannot allocate zero or negative size of memory.\n", .{});
				}

				const shit: []u8 = try allocator.alloc(u8, @as(usize, @bitCast(a)) + 1);

				shit[shit.len - 1] = 0;

				try stack.append(@bitCast(@intFromPtr(shit.ptr)));
				try allocation_stack.append(shit);
			},
			.OP_MEMW => {
				const ptr = stack.popOrNull() orelse 0;

				const shit: [*:0]u8 = @ptrFromInt(@as(usize, @bitCast(ptr)));

				const offset = stack.popOrNull() orelse 0;
				const data = stack.popOrNull() orelse 0;

				shit[@bitCast(offset)] = @truncate(@as(u64, @bitCast(data)));
			},
			.OP_STR => {
				const stuff: []u8 = try allocator.alloc(u8, opps[i].params.items.len + 1);

				for (0..opps[i].params.items.len) |j| {
					stuff[j] = @truncate(opps[i].params.items[j]);
				}

				stuff[stuff.len - 1] = 0;

				try stack.append(@bitCast(@intFromPtr(stuff.ptr)));
				try allocation_stack.append(stuff);
			},
			.OP_PRINTLN => {
				const ptr = stack.popOrNull() orelse 0;

				const str: [*:0]u8 = @ptrFromInt(@as(usize, @bitCast(ptr)));

				try stdout.print("{s}\n", .{str});
			},
			.OP_PRINT => {
				const ptr = stack.popOrNull() orelse 0;

				const str: [*:0]u8 = @ptrFromInt(@as(usize, @bitCast(ptr)));

				try stdout.print("{s}", .{str});
			},
			.OP_PARF => {
				try stdout.print("meow\n", .{});
			},
			else => continue
		}
	}

	for (0..allocation_stack.items.len) |j| {
		allocator.free(allocation_stack.items[j]);
	}

	allocation_stack.deinit();
	stack.deinit();
}
