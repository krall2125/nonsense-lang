const bytecode = @import("bytecode.zig");
const lexer = @import("lexer.zig");
const std = @import("std");

pub const Precedence = enum {
	NONE,
	ASSIGNMENT,
	EQUALITY,
	COMPARISON,
	TERM,
	FACTOR,
	UNARY,
	CALL,
	PRIMARY
};

pub const ParseError = error {
	UnexpectedToken,
	UnableToAddInstr,
};

const CompilerState = struct {
	opps: *std.ArrayList(bytecode.BytecodeOp),
	tokens: []lexer.Token,
	iter: usize,

	pub fn add_op(self: *CompilerState, op_t: bytecode.OpType, arg: u64) ParseRule!void {
		self.opps.append(bytecode.BytecodeOp {
			.typ = op_t,
			.params = [_]u64{arg}
		}) catch {
			return ParseError.UnableToAddInstr;
		};
	}

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

	pub fn expression(self: *CompilerState) void {
		self.parse_prec(.ASSIGNMENT);
	}

	pub fn number(self: *CompilerState) !void {
		const val = std.fmt.parseInt(u64, self.tokens[self.iter - 1].lexeme, 10) catch 0;

		try self.add_op(.OP_PUSH, val);
	}

	pub fn grouping(self: *CompilerState) !void {
		self.expression();

		try self.consume(.TOK_RPAR);
	}

	pub fn unary(self: *CompilerState) !void {
		const op_t = self.tokens[self.iter - 1].typ;

		self.parse_prec(.UNARY);

		switch (op_t) {
			.TOK_MINUS => try self.add_op(.OP_NEG, 0),
			else => return
		}
	}

	pub fn binary(self: *CompilerState) !void {
		const op_t = self.tokens[self.iter - 1].typ;
		const rule = get_rule(op_t);

		self.parse_prec(@enumFromInt(@intFromEnum(rule.prec) + 1));

		switch (op_t) {
			.TOK_PLUS => try self.add_op(.OP_ADD, 0),
			.TOK_MINUS => try self.add_op(.OP_SUBTR, 0),
			.TOK_STAR => try self.add_op(.OP_MULTI, 0),
			.TOK_SLASH => try self.add_op(.OP_DIV, 0),
			.TOK_PERCENT => try self.add_op(.OP_MOD, 0),
			.TOK_EQUAL => try self.add_op(.OP_EQ, 0),
			.TOK_GREATER => try self.add_op(.OP_GT, 0),
			.TOK_LESS => try self.add_op(.OP_LT, 0),
			else => return
		}
	}

	pub fn parse_prec(self: *CompilerState, prec: Precedence) void {
		self.advance();

		const prefix_rule = get_rule(self.tokens[self.iter - 1].typ).prefix;
		if (prefix_rule == null) {
			self.err("Expected expression.\n", .{});
			return;
		}

		try prefix_rule(self);

		const numeric_prec = @intFromEnum(prec);

		while (numeric_prec <= @intFromEnum(get_rule(self.tokens[self.iter].typ).prec)) {
			self.advance();

			const infix_rule = get_rule(self.tokens[self.iter - 1].typ).infix;

			infix_rule(self);
		}
	}

	pub fn advance(self: *CompilerState) void {
		self.iter += 1;
	}
};

fn make_op(typ: bytecode.OpType, params: []u64) bytecode.BytecodeOp {
	return bytecode.BytecodeOp {
		.typ = typ,
		.params = params
	};
}

const ParseRule = struct {
	prefix: *const fn (*CompilerState) ParseError!void,
	infix: *const fn (*CompilerState) ParseError!void,
	prec: Precedence
};

fn get_rule(t: lexer.TokenType) *ParseRule {
	return &rules[@intFromEnum(t)];
}

const rules = [_]ParseRule {
	ParseRule { null, CompilerState.binary, Precedence.TERM },
	ParseRule { null, CompilerState.binary, Precedence.TERM },
	ParseRule { null, CompilerState.binary, Precedence.FACTOR },
	ParseRule { null, CompilerState.binary, Precedence.FACTOR },
	ParseRule { null, CompilerState.binary, Precedence.FACTOR },
	ParseRule { CompilerState.grouping, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, CompilerState.binary, Precedence.EQUALITY },
	ParseRule { CompilerState.unary, null, Precedence.UNARY },
	ParseRule { null, CompilerState.binary, Precedence.COMPARISON },
	ParseRule { null, CompilerState.binary, Precedence.COMPARISON },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE }, // string
	ParseRule { CompilerState.number, null, Precedence.NONE },
	ParseRule { null, null, Precedence.NONE }, // identifier
	ParseRule { null, null, Precedence.NONE }, // none
};
