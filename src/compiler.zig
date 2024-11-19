const std = @import("std");
const bytecode = @import("bytecode.zig");

pub fn compile(allocator: std.mem.Allocator, opps: []bytecode.BytecodeOp, filename: []u8) !void {
	// because zig fucking sucks at that.
	var dotasm: [4]u8 = [4]u8{0, 0, 0, 0};
	dotasm[0] = '.';
	dotasm[1] = 'a';
	dotasm[2] = 's';
	dotasm[3] = 'm';
	var doto: [2]u8 = [2]u8{0, 0};
	doto[0] = '.';
	doto[1] = 'o';

	const things: []const []const u8 = &[_][]u8{filename, dotasm[0..]};
	const thingso: []const []const u8 = &[_][]u8{filename, doto[0..]};

	const filename_asm = try std.mem.concat(allocator, u8, things[0..]);
	const filename_o = try std.mem.concat(allocator, u8, thingso[0..]);
	const file = try std.fs.cwd().createFile(filename_asm, .{});

	defer file.close();
	defer allocator.free(filename_asm);
	defer allocator.free(filename_o);

	var strings = std.ArrayList([]u8).init(allocator);
	defer strings.deinit();

	var writer = file.writer();

	try writer.print("global _start\n", .{});
	try writer.print("section .text\n", .{});
	try writer.print("_start:\n", .{});
	for (0..opps.len) |i| {
		try writer.print(".instr_{d}:\n", .{i});
		switch (opps[i].typ) {
			.OP_PUSH => try writer.print("\tpush {d}\n", .{opps[i].params.items[0]}),
			.OP_POP => try writer.print("\tpop rax\n", .{}),
			.OP_DUP => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpush rax\n", .{});
				try writer.print("\tpush rax\n", .{});
			},
			.OP_ADD => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tlea rdi, [rbx+rax]\n", .{});
				try writer.print("\tpush rdi\n", .{});
			},
			.OP_SUBTR => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tsub rbx, rax\n", .{});
				try writer.print("\tpush rbx\n", .{});
			},
			.OP_MULTI => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tmul rbx\n", .{});
				try writer.print("\tpush rax\n", .{});
			},
			.OP_DIV => {
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tcqo\n", .{});
				try writer.print("\tidiv rbx\n", .{});
				try writer.print("\tpush rax\n", .{});
			},
			.OP_MOD => {
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tcqo\n", .{});
				try writer.print("\tidiv rbx\n", .{});
				try writer.print("\tpush rdx\n", .{});
			},
			.OP_PUTC => {
				try writer.print("\tmov rax, 1\n", .{});
				try writer.print("\tmov rdi, 1\n", .{});
				try writer.print("\tmov rsi, rsp\n", .{});
				try writer.print("\tmov rdx, 1\n", .{});
				try writer.print("\tsyscall\n", .{});
				try writer.print("\tpop rax\n", .{});
			},
			.OP_PUTN => {
				std.debug.print("Warning! putn operation is not implemented for compilation.", .{});
			},
			.OP_JUMP_IF_FALSE => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tcmp rax, 0\n", .{});
				try writer.print("\tje .instr_{d}\n", .{opps[i].params.items[0] + 1});
			},
			.OP_JUMP => {
				try writer.print("\tjmp .instr_{d}\n", .{opps[i].params.items[0] + 1});
			},
			.OP_EQ => {
				try writer.print("\txor rcx, rcx\n", .{});
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tcmp rax, rbx\n", .{});
				try writer.print("\tmov rdx, 1\n", .{});
				try writer.print("\tcmove rcx, rdx\n", .{});
				try writer.print("\tpush rcx\n", .{});
			},
			.OP_NOT => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\txor rax, 1\n", .{});
				try writer.print("\tpush rax\n", .{});
			},
			.OP_GT => {
				try writer.print("\txor rcx, rcx\n", .{});
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tcmp rbx, rax\n", .{});
				try writer.print("\tmov rdx, 1\n", .{});
				try writer.print("\tcmovg rcx, rdx\n", .{});
				try writer.print("\tpush rcx\n", .{});
			},
			.OP_LT => {
				try writer.print("\txor rcx, rcx\n", .{});
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tcmp rbx, rax\n", .{});
				try writer.print("\tmov rdx, 1\n", .{});
				try writer.print("\tcmovl rcx, rdx\n", .{});
				try writer.print("\tpush rcx\n", .{});
			},
			.OP_MEM => {
				try writer.print("\tpush mem\n", .{});
			},
			.OP_MEMW => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tmov [rbx], rax\n", .{});
				try writer.print("\tpush rbx\n", .{});
			},
			.OP_MEMR => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tmov rbx, [rax]\n", .{});
				try writer.print("\tpush rax\n", .{});
				try writer.print("\tpush rbx\n", .{});
			},
			.OP_STR => {
				var shit = try allocator.alloc(u8, opps[i].params.items.len);

				for (0..opps[i].params.items.len) |j| {
					shit[j] = @truncate(opps[i].params.items[j]);
				}

				try strings.append(shit);
			},
			.OP_PRINTLN => {
				try writer.print("\tmov rax, 1\n", .{});
				try writer.print("\tmov rdi, 1\n", .{});
				try writer.print("\tmov rsi, STR_{d}\n", .{strings.items.len});
				try writer.print("\tmov rdx, {d}\n", .{strings.items[strings.items.len - 1].len});
				try writer.print("\tsyscall\n", .{});
				try writer.print("\tmov rax, 1\n", .{});
				try writer.print("\tmov rdi, 1\n", .{});
				try writer.print("\tmov rsi, STR_NEWLINE\n", .{});
				try writer.print("\tmov rdx, 1\n", .{});
				try writer.print("\tsyscall\n", .{});
			},
			.OP_PRINT => {
				try writer.print("\tmov rax, 1\n", .{});
				try writer.print("\tmov rdi, 1\n", .{});
				try writer.print("\tmov rsi, STR_{d}\n", .{strings.items.len});
				try writer.print("\tmov rdx, {d}\n", .{strings.items[strings.items.len - 1].len});
				try writer.print("\tsyscall\n", .{});
			},
			.OP_PARF => {
				try writer.print("\tmov rax, 1\n", .{});
				try writer.print("\tmov rdi, 1\n", .{});
				try writer.print("\tmov rsi, STR_PARF\n", .{});
				try writer.print("\tmov rdx, 5\n", .{});
				try writer.print("\tsyscall\n", .{});
			},
			.OP_SWAP => {
				try writer.print("\tpop rax\n", .{});
				try writer.print("\tpop rbx\n", .{});
				try writer.print("\tpush rax\n", .{});
				try writer.print("\tpush rbx\n", .{});
			},
			else => continue,
		}
	}
	try writer.print(".instr_{d}:\n", .{opps.len});
	try writer.print("\tmov rax, 60\n", .{});
	try writer.print("\tmov rdi, 0\n", .{});
	try writer.print("\tsyscall\n", .{});

	try writer.print("\nsection .bss\n", .{});
	try writer.print("mem resb 2048\n", .{});
	try writer.print("\nsection .data\n", .{});
	try writer.print("STR_PARF db \"meow\", 10\n", .{});
	try writer.print("STR_NEWLINE db 10\n", .{});

	for (0..strings.items.len) |i| {
		try writer.print("STR_{d} db ", .{i + 1});
		for (0..strings.items[i].len) |j| {
			try writer.print("{d}, ", .{strings.items[i][j]});
		}
		try writer.print("\n", .{});
		allocator.free(strings.items[i]);
	}

	// why does zig fucking suck at that
	var yasm: [4]u8 = [4]u8{0,0,0,0};
	yasm[0] = 'y';
	yasm[1] = 'a';
	yasm[2] = 's';
	yasm[3] = 'm';
	var felf: [7]u8 = [7]u8{0,0,0,0,0,0,0};
	felf[0] = '-';
	felf[1] = 'f';
	felf[2] = 'e';
	felf[3] = 'l';
	felf[4] = 'f';
	felf[5] = '6';
	felf[6] = '4';
	var dasho: [2]u8 = [2]u8{0, 0};
	dasho[0] = '-';
	dasho[1] = 'o';
	var elldee: [2]u8 = [2]u8{0, 0};
	elldee[0] = 'l';
	elldee[1] = 'd';

	const result1 = try std.process.Child.run(.{
		.allocator = allocator,
		.argv = &[_][]u8{&yasm, &felf, filename_asm, &dasho, filename_o}
	});
	const result2 = try std.process.Child.run(.{
		.allocator = allocator,
		.argv = &[_][]u8{&elldee, &dasho, filename, filename_o}
	});

	defer {
		allocator.free(result1.stdout);
		allocator.free(result1.stderr);
	}

	std.debug.print("{s}", .{result1.stdout});
	std.debug.print("{s}", .{result1.stderr});

	defer {
		allocator.free(result2.stdout);
		allocator.free(result2.stderr);
	}

	std.debug.print("{s}", .{result2.stdout});
	std.debug.print("{s}", .{result2.stderr});
}
