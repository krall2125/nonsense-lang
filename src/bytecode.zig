const std = @import("std");
const lexer = @import("lexer.zig");

pub const OpType = enum {
	OP_PUSH,
	OP_POP,
	OP_DUP,
	OP_ADD,
	OP_SUBTR,
	OP_MULTI,
	OP_DIV,
	OP_MOD,
	OP_PUTC,
	OP_PUTN,
	OP_JUMP_IF_FALSE,
	OP_END,
	OP_JUMP,
	OP_WHILE,
	OP_DEBUG,
	OP_EQ,
	OP_NOT,
	OP_GT,
	OP_LT,
	OP_MEM,
	OP_MEMW,
	OP_MEMR,
	OP_OPENF,
	OP_CLOSEF,
	OP_READF,
	OP_WRITEF,
	OP_STR,
	OP_PRINTLN,
	OP_PRINT,
	OP_PARF,
	OP_SWAP,
};

pub const BytecodeOp = struct {
	typ: OpType,
	params: []u64
};

fn make_op(typ: OpType, params: []u64) !BytecodeOp {
	return BytecodeOp {
		.typ = typ,
		.params = params
	};
}

pub const ParseError = error {
	UnexpectedToken,
};

const CompilerState = struct {
	opps: *std.ArrayList(BytecodeOp),
	positions: *std.ArrayList(usize),
	tokens: []lexer.Token,
	iter: usize,

	pub fn err(self: *CompilerState, format: []const u8, comptime args: anytype) void {
		std.debug.print("Error at token ({s} '{s}')\n", .{@tagName(self.tokens[self.iter]), self.tokens[self.iter].lexeme});
		std.debug.print(format, args);
	}

	pub fn consume(self: *CompilerState, t: lexer.TokenType) !void {
		if (self.tokens[self.iter].typ != t) {
			err("Unexpected token {s}", .{@tagName(self.tokens[self.iter].typ)});
			return ParseError.UnexpectedToken;
		}

		self.iter += 1;
	}

	pub fn match(self: *CompilerState, t: lexer.TokenType) !void {
	}

	pub fn expression(self: *CompilerState) void {
	}

	pub fn number(self: *CompilerState) !void {
		const val = std.fmt.parseInt(u64, self.tokens[self.iter - 1].lexeme, 10) catch 0;

		try self.opps.append(make_op(.OP_PUSH, &[_]u64{val}));
	}

	pub fn grouping(self: *CompilerState) !void {
		self.expression();

	}
};

pub fn compile(allocator: std.mem.Allocator, tokens: []lexer.Token) !std.ArrayList(BytecodeOp) {
	var opps = std.ArrayList(BytecodeOp).init(allocator);

	var positions = std.ArrayList(usize).init(allocator);

	var compiler = CompilerState {
		.opps = &opps,
		.positions = &positions,
		.tokens = tokens
	};

	for (tokens) |token| {
		switch (token.typ) {
			.TOK_INT => {
				const val = try std.fmt.parseInt(u64, token.lexeme.items, 10);

				var shit = [_]u64{val};
				try opps.append(try make_op(allocator, .OP_PUSH, &shit));
			},
			.TOK_COLON => try opps.append(try make_op(allocator, .OP_DUP, &[_]u64{})),
			.TOK_PLUS => try opps.append(try make_op(allocator, .OP_ADD, &[_]u64{})),
			.TOK_MINUS => try opps.append(try make_op(allocator, .OP_SUBTR, &[_]u64{})),
			.TOK_STAR => try opps.append(try make_op(allocator, .OP_MULTI, &[_]u64{})),
			.TOK_SLASH => try opps.append(try make_op(allocator, .OP_DIV, &[_]u64{})),
			.TOK_PERCENT => try opps.append(try make_op(allocator, .OP_MOD, &[_]u64{})),
			.TOK_PUTC => try opps.append(try make_op(allocator, .OP_PUTC, &[_]u64{})),
			.TOK_PUTN => try opps.append(try make_op(allocator, .OP_PUTN, &[_]u64{})),
			.TOK_END => {
				const index = positions.popOrNull().?;

				if (opps.items[opps.items[index].params.items[0]].typ == .OP_WHILE) {
					var shit = [_]u64{opps.items[index].params.items[0]};
					try opps.append(try make_op(allocator, .OP_JUMP, &shit));
				}

				try opps.append(try make_op(allocator, .OP_END, &[_]u64{}));

				opps.items[index].params.items[0] = opps.items.len - 1;
			},
			.TOK_WHILE => {
				try opps.append(try make_op(allocator, .OP_WHILE, &[_]u64{}));

				try positions.append(opps.items.len - 1);
			},
			.TOK_DEBUG => try opps.append(try make_op(allocator, .OP_DEBUG, &[_]u64{})),
			.TOK_POP => try opps.append(try make_op(allocator, .OP_POP, &[_]u64{})),
			.TOK_EQUAL => try opps.append(try make_op(allocator, .OP_EQ, &[_]u64{})),
			.TOK_TILDE => try opps.append(try make_op(allocator, .OP_NOT, &[_]u64{})),
			.TOK_GREATER => try opps.append(try make_op(allocator, .OP_GT, &[_]u64{})),
			.TOK_LESS => try opps.append(try make_op(allocator, .OP_LT, &[_]u64{})),
			.TOK_MEM => try opps.append(try make_op(allocator, .OP_MEM, &[_]u64{})),
			.TOK_MEMW => try opps.append(try make_op(allocator, .OP_MEMW, &[_]u64{})),
			.TOK_MEMR => try opps.append(try make_op(allocator, .OP_MEMR, &[_]u64{})),
			.TOK_OPENF => try opps.append(try make_op(allocator, .OP_OPENF, &[_]u64{})),
			.TOK_CLOSEF => try opps.append(try make_op(allocator, .OP_CLOSEF, &[_]u64{})),
			.TOK_READF => try opps.append(try make_op(allocator, .OP_READF, &[_]u64{})),
			.TOK_WRITEF => try opps.append(try make_op(allocator, .OP_WRITEF, &[_]u64{})),
			.TOK_PRINTLN => try opps.append(try make_op(allocator, .OP_PRINTLN, &[_]u64{})),
			.TOK_PRINT => try opps.append(try make_op(allocator, .OP_PRINT, &[_]u64{})),
			.TOK_PARF => try opps.append(try make_op(allocator, .OP_PARF, &[_]u64{})),
			.TOK_IF => {
				var shit = [_]u64{0};
				try opps.append(try make_op(allocator, .OP_JUMP_IF_FALSE, &shit));
				try positions.append(opps.items.len - 1);
			},
			.TOK_ELSE => {
				const index = positions.popOrNull().?;

				var shit = [_]u64{0};
				try opps.append(try make_op(allocator, .OP_JUMP, &shit));

				opps.items[index].params.items[0] = opps.items.len - 1;

				try positions.append(opps.items.len - 1);
			},
			.TOK_DO => {
				const index = positions.popOrNull().?;
				var shit = [_]u64{index};
				try opps.append(try make_op(allocator, .OP_JUMP_IF_FALSE, &shit));
				try positions.append(opps.items.len - 1);
			},
			.TOK_SWAP => try opps.append(try make_op(allocator, .OP_SWAP, &[_]u64{})),
			.TOK_STRING => {
				const str64 = try allocator.alloc(u64, token.lexeme.items.len);

				for (0..str64.len) |j| {
					str64[j] = token.lexeme.items[j];
				}

				try opps.append(try make_op(allocator, .OP_STR, str64));

				allocator.free(str64);
			},
			else => {}
		}
	}

	positions.deinit();

	return opps;
}
