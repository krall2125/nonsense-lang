const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

pub const OpType = enum {
	OP_PUSH,
	OP_POP,
	OP_DUP,
	OP_ADD,
	OP_SUBTR,
	OP_MULTI,
	OP_DIV,
	OP_MOD,
	OP_NEG,
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
	param: u64
};

pub fn compile(allocator: std.mem.Allocator, tokens: []lexer.Token) !std.ArrayList(BytecodeOp) {
	var opps = std.ArrayList(BytecodeOp).init(allocator);

	var compiler = parser.CompilerState {
		.opps = &opps,
		.tokens = tokens,
		.iter = 0,
	};

	compiler.expression();

	return opps;
}
