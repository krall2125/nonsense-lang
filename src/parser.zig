const bytecode = @import("bytecode.zig");
const lexer = @import("lexer.zig");
const std = @import("std");

pub const Precedence = enum {

};

pub const ParseError = error {
	UnexpectedToken,
};

const CompilerState = struct {
	opps: *std.ArrayList(bytecode.BytecodeOp),
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

	pub fn expression(self: *CompilerState) void {
	}

	pub fn number(self: *CompilerState) !void {
		const val = std.fmt.parseInt(u64, self.tokens[self.iter - 1].lexeme, 10) catch 0;

		try self.opps.append(make_op(.OP_PUSH, &[_]u64{val}));
	}

	pub fn grouping(self: *CompilerState) void {
		self.expression();

		self.consume(.TOK_RPAR);
	}

	pub fn unary(self: *CompilerState) !void {
		const op_t = self.tokens[self.iter - 1].typ;

		self.expression();

		switch (op_t) {
			.TOK_MINUS => try self.opps.append(make_op(.OP_NEG, &[_]u64{})),
			else => return
		}
	}

	pub fn parse_prec(self: *CompilerState, prec: Precedence) void {

	}
};

fn make_op(typ: bytecode.OpType, params: []u64) bytecode.BytecodeOp {
	return bytecode.BytecodeOp {
		.typ = typ,
		.params = params
	};
}
