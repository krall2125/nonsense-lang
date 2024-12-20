const std = @import("std");
const lexer = @import("lexer.zig");
const bytecode = @import("bytecode.zig");
const compiler = @import("compiler.zig");

pub fn main() !void {
	// init gpa
	var gpa = std.heap.GeneralPurposeAllocator(.{.safety = true}){};

	var debug_dump_tokens = false;
	var debug_dump_ops = false;
	for (std.os.argv[1..]) |i| {
		if (i[0] == '-') {
			if (std.mem.eql(u8, std.mem.span(i[1..]), "dump_tokens")) {
				debug_dump_tokens = true;
			}
			else if (std.mem.eql(u8, std.mem.span(i[1..]), "dump_ops")) {
				debug_dump_ops = true;
			}

			continue;
		}

		if (!std.mem.endsWith(u8, std.mem.span(i), ".nons")) {
			continue;
		}

		const tokens = try lexer.lex(gpa.allocator(), std.mem.span(i));

		if (debug_dump_tokens) {
			std.debug.print("--> {s: <64} <--\n", .{"TOKEN DUMP"});
			for (0..tokens.items.len) |j| {
				const stuff = try std.fmt.allocPrint(gpa.allocator(),
					"[{s} '{s}']",
					.{
						@tagName(tokens.items[j].typ),
						tokens.items[j].lexeme.items
					});

				std.debug.print(" -> {s: <64} <-\n", .{stuff});

				gpa.allocator().free(stuff);
			}
			std.debug.print("--> {s: <64} <--\n", .{"END TOKEN DUMP"});
		}

		const ops = try bytecode.compile(gpa.allocator(), tokens.items);
		if (debug_dump_ops) {
			std.debug.print("--> {s: <64} <--\n", .{"OPERATION DUMP"});
			for (0..ops.items.len) |j| {
				const stuff = try std.fmt.allocPrint(gpa.allocator(),
					"({s} {d})",
					.{
						@tagName(ops.items[j].typ),
						ops.items[j].param
					});

				std.debug.print(" -> {s: <64} <-\n", .{stuff});

				gpa.allocator().free(stuff);
			}
			std.debug.print("--> {s: <64} <--\n", .{"END OPERATION DUMP"});
		}

		for (0..tokens.items.len) |j| {
			tokens.items[j].lexeme.deinit();
		}
		tokens.deinit();

		var filename: []u8 = std.mem.span(i);
		try compiler.compile(gpa.allocator(), ops.items, filename[0..(filename.len - 5)]);

		ops.deinit();
	}

	_ = gpa.deinit();
}
