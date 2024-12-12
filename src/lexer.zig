const std = @import("std");

pub const TokenType = enum {
	TOK_COLON,	 // :
	TOK_PLUS,	 // +
	TOK_MINUS,	 // -
	TOK_STAR,	 // *
	TOK_SLASH,	 // /
	TOK_PERCENT,	 // %
	// TOK_PUTC,	 // putc
	// TOK_PUTN,	 // putn
	TOK_END,	 // end
	TOK_WHILE,	 // while
	TOK_DEBUG,	 // debug
	// TOK_POP,
	TOK_EQUAL,	 // =
	TOK_TILDE,	 // ~
	TOK_GREATER,	 // gt, >
	TOK_LESS,	 // lt, <
	TOK_MEM,	 // mem
	TOK_MEMW,	 // memw
	TOK_MEMR,	 // memr
	TOK_OPENF,	 // openf
	TOK_CLOSEF,	 // closef
	TOK_READF,	 // readf
	TOK_WRITEF,	 // writef
	TOK_VAR,         // var

	TOK_PRINTLN,	 // println
	TOK_PRINT,	 // print
	TOK_PARF,	 // parf
	
	TOK_IF,
	TOK_ELSE,
	TOK_DO,
	// TOK_SWAP,
	
	TOK_STRING,	 // any text with quotes around it
	TOK_INT,	 // any integer
	TOK_IDENTIFIER,  // any identifier
	
	TOK_NONE
};

pub const Token = struct {
	typ: TokenType,
	lexeme: std.ArrayList(u8),
};

fn make_token(allocator: std.mem.Allocator, typ: TokenType) Token {
	return Token {
		.typ = typ,
		.lexeme = std.ArrayList(u8).init(allocator)
	};
}

fn number_token(allocator: std.mem.Allocator, text: []u8, iter: *usize) !Token {
	var token = make_token(allocator, .TOK_INT);

	while (std.ascii.isDigit(text[iter.*]) and iter.* < text.len) : (iter.* += 1) {
		try token.lexeme.append(text[iter.*]);
	}

	iter.* -= 1;

	return token;
}

fn string_token(allocator: std.mem.Allocator, text: []u8, iter: *usize) !Token {
	var token = make_token(allocator, .TOK_STRING);

	iter.* += 1;

	while (text[iter.*] != '"' and iter.* < text.len) : (iter.* += 1) {
		try token.lexeme.append(text[iter.*]);
	}

	return token;
}

fn word_token(allocator: std.mem.Allocator, text: []u8, iter: *usize) !Token {
	var token = make_token(allocator, .TOK_IDENTIFIER);

	while (std.ascii.isAlphanumeric(text[iter.*]) and iter.* < text.len) : (iter.* += 1) {
		try token.lexeme.append(text[iter.*]);
	}

	if (std.mem.eql(u8, token.lexeme.items, "putc")) {
		token.typ = .TOK_PUTC;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "putn")) {
		token.typ = .TOK_PUTN;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "end")) {
		token.typ = .TOK_END;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "while")) {
		token.typ = .TOK_WHILE;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "debug")) {
		token.typ = .TOK_DEBUG;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "gt")) {
		token.typ = .TOK_GREATER;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "lt")) {
		token.typ = .TOK_LESS;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "mem")) {
		token.typ = .TOK_MEM;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "memw")) {
		token.typ = .TOK_MEMW;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "memr")) {
		token.typ = .TOK_MEMR;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "openf")) {
		token.typ = .TOK_OPENF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "closef")) {
		token.typ = .TOK_CLOSEF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "readf")) {
		token.typ = .TOK_READF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "writef")) {
		token.typ = .TOK_WRITEF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "println")) {
		token.typ = .TOK_PRINTLN;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "parf")) {
		token.typ = .TOK_PARF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "if")) {
		token.typ = .TOK_IF;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "else")) {
		token.typ = .TOK_ELSE;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "do")) {
		token.typ = .TOK_DO;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "pop")) {
		token.typ = .TOK_POP;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "print")) {
		token.typ = .TOK_PRINT;
	}
	else if (std.mem.eql(u8, token.lexeme.items, "swap")) {
		token.typ = .TOK_SWAP;
	}

	return token;
}

fn read_token(allocator: std.mem.Allocator, text: []u8, iter: *usize) !Token {
	switch (text[iter.*]) {
		':' => return make_token(allocator, .TOK_COLON),
		'+' => return make_token(allocator, .TOK_PLUS),
		'-' => return make_token(allocator, .TOK_MINUS),
		'*' => return make_token(allocator, .TOK_STAR),
		'/' => return make_token(allocator, .TOK_SLASH),
		'%' => return make_token(allocator, .TOK_PERCENT),
		'=' => return make_token(allocator, .TOK_EQUAL),
		'~' => return make_token(allocator, .TOK_TILDE),
		'"' => return string_token(allocator, text, iter),
		else => {
			if (std.ascii.isDigit(text[iter.*])) {
				return number_token(allocator, text, iter);
			}
			else if (std.ascii.isAlphanumeric(text[iter.*])) {
				return word_token(allocator, text, iter);
			}
			else {
				return make_token(allocator, .TOK_NONE);
			}
		},
	}
}

pub fn lex(allocator: std.mem.Allocator, filename: []u8) !std.ArrayList(Token) {
	// open file
	var file = try std.fs.cwd().openFile(filename, .{});
	defer file.close();

	// get the readers
	var buf_reader = std.io.bufferedReader(file.reader());
	var in_stream = buf_reader.reader();

	// get the stats of the file
	const file_stat = try file.stat();

	// allocate the buffer for the contents of the file
	const buffer = try allocator.alloc(u8, file_stat.size);

	// read
	try in_stream.readNoEof(buffer);

	var iter: usize = 0;

	var tokens = std.ArrayList(Token).init(allocator);

	// read all the tokens
	while (iter < buffer.len) : (iter += 1) {
		const token = try read_token(allocator, buffer, &iter);

		if (token.typ == .TOK_NONE) {
			token.lexeme.deinit();
			continue;
		}

		try tokens.append(token);
	}

	// free buffer
	allocator.free(buffer);

	return tokens;
}
