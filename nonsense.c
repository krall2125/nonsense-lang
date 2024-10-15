#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

int64_t tape[128] = {0};
int64_t stack[256] = {0};
int64_t *allocstack[256] = {NULL};
int64_t memsize[256] = {0};

int32_t tapepos = 0, top = 0, alloctop = 0;
// TODO: TEST MEM ALLOC AND IMPLEMENT FILE IO
typedef enum {
	OP_INCITER, // >
	OP_DECITER, // <
	OP_DOLLAR,  // $
	OP_ACCESS,  // &
	OP_POP,     // !

	OP_GROW,    // :
	OP_UNGROW,  // ;

	OP_ADD,     // +
	OP_SUBTR,   // -
	OP_MULTI,   // *
	OP_DIV,     // /
	OP_MODULO,

	OP_PUTC,    // .
	OP_PUTN,    // =

	OP_JUMP_IF_FALSE,  // emitted by multiple characters
	OP_END,            // e
	OP_JUMP,

	OP_WHILE,   // w
	OP_LOOPS,   // [
	OP_LOOPE,   // ]
	OP_CLEAR,   // `
	OP_DEBUG,   // 1
	
	OP_EQ,     // _
	OP_NOT,    // ~
	OP_GT,     // g
	OP_LT,     // l
	
	OP_ALLOC,  // @
	OP_WRITE,  // |
	OP_READI,  // ^
	OP_FREE,   // f
	OP_LEN,    // s

	OP_OPENF,  // o
	OP_READF,  // r
	OP_WRITEF, // t
	OP_CLOSEF, // c
} Bytecode;

typedef struct {
	int64_t *bcode;
	size_t size;
	size_t cap;
} BytecodeList;

BytecodeList *init_list() {
	BytecodeList *list = malloc(sizeof(BytecodeList));

	list->bcode = malloc(sizeof(int64_t) * 8);
	list->cap = 8;
	list->size = 0;

	return list;
}

void append_list(BytecodeList *list, int64_t elem) {
	if (list->size >= list->cap) {
		list->cap *= 2;
		list->bcode = realloc(list->bcode, list->cap * sizeof(int64_t));
	}
	
	list->bcode[list->size++] = elem;
}

int64_t pop_list(BytecodeList *list) {
	if (list->size <= 0) {
		return -1;
	}

	return list->bcode[--list->size];
}

void free_list(BytecodeList *list) {
	free(list->bcode);
	free(list);
}

BytecodeList *read_bytecode(char *code);

void run(BytecodeList *bytecode);

char *op_str(Bytecode op) {
	switch (op) {
		case OP_INCITER: return "OP_INCITER";
		case OP_DECITER: return "OP_DECITER";
		case OP_DOLLAR: return "OP_DOLLAR";
		case OP_ACCESS: return "OP_ACCESS";
		case OP_POP: return "OP_POP";
		case OP_GROW: return "OP_GROW";
		case OP_UNGROW: return "OP_UNGROW";
		case OP_ADD: return "OP_ADD";
		case OP_SUBTR: return "OP_SUBTR";
		case OP_MULTI: return "OP_MULTI";
		case OP_DIV: return "OP_DIV";
		case OP_MODULO: return "OP_MODULO";
		case OP_PUTC: return "OP_PUTC";
		case OP_PUTN: return "OP_PUTN";
		case OP_JUMP_IF_FALSE: return "OP_JUMP_IF_FALSE";
		case OP_JUMP: return "OP_JUMP";
		case OP_END: return "OP_END";
		case OP_WHILE: return "OP_WHILE";
		case OP_LOOPS: return "OP_LOOPS";
		case OP_LOOPE: return "OP_LOOPE";
		case OP_CLEAR: return "OP_CLEAR";
		case OP_DEBUG: return "OP_DEBUG";
		case OP_EQ: return "OP_EQ";
		case OP_NOT: return "OP_NOT";
		case OP_GT: return "OP_GT";
		case OP_LT: return "OP_LT";
		case OP_ALLOC: return "OP_ALLOC";
		case OP_WRITE: return "OP_WRITE";
		case OP_READI: return "OP_READI";
		case OP_FREE: return "OP_FREE";
		case OP_LEN: return "OP_LEN";
		case OP_OPENF: return "OP_OPENF";
		case OP_READF: return "OP_READF";
		case OP_WRITEF: return "OP_WRITEF";
		case OP_CLOSEF: return "OP_CLOSEF";
	}
}

int main(int argc, char **argv) {
	for (int i = 1; i < argc; i++) {
		FILE *maybe = fopen(argv[i], "r");

		if (maybe == NULL) {
			fprintf(stderr, "Couldn't open file: %s\n", argv[i]);
			return 0;
		}

		fseek(maybe, 0L, SEEK_END);
		long bytes = ftell(maybe);

		char *code = malloc(sizeof(char) * (bytes + 1));

		rewind(maybe);

		size_t bytes_read = fread(code, sizeof(char), bytes, maybe);

		code[bytes_read] = '\0';

		fclose(maybe);

		BytecodeList *bytecode = read_bytecode(code);
/* #define PRINT_OPS */
#ifdef PRINT_OPS
		for (int i = 0; i < bytecode->size; i++) {
			printf("%d. %s", i, op_str(bytecode->bcode[i]));
			if (bytecode->bcode[i] == OP_JUMP || bytecode->bcode[i] == OP_JUMP_IF_FALSE) {
				printf("(%ld)", bytecode->bcode[i + 1]);
				i++;
			}
			printf("\n");
		}
#endif

		run(bytecode);

		for (int i = 0; i < 256; i++) {
			if (allocstack[i] == NULL) break;

			free(allocstack[i]);
		}

		free_list(bytecode);

		free(code);
	}
	return 0;
}

BytecodeList *read_bytecode(char *code) {
	BytecodeList *list = init_list();
	BytecodeList *positions = init_list();
	for (int i = 0; i < strlen(code); i++) {
		switch (code[i]) {
			case '>': {
				append_list(list, OP_INCITER);
				break;
			}
			case '<': {
				append_list(list, OP_DECITER);
				break;
			}
  			case '$': {
				append_list(list, OP_DOLLAR);
				break;
			}
			case '&': {
				append_list(list, OP_ACCESS);
				break;
			}
			case ':': {
				append_list(list, OP_GROW);
				break;
			}
			case ';': {
				append_list(list, OP_UNGROW);
				break;
			}
  			case '+': {
  				append_list(list, OP_ADD);
				break;
			}
	  		case '-': {
				append_list(list, OP_SUBTR);
				break;
			}
  			case '*': {
				append_list(list, OP_MULTI);
				break;
			}
			case '/': {
				append_list(list, OP_DIV);
				break;
			}
  			case '%': {
				append_list(list, OP_MODULO);
				break;
			}
  			case '.': {
				append_list(list, OP_PUTC);
				break;
			}
  			case '=': {
				append_list(list, OP_PUTN);
				break;
			}
  			case '!': {
				append_list(list, OP_POP);
				break;
			}
			case '?': {
				append_list(list, OP_JUMP_IF_FALSE);
				append_list(list, 0);
				append_list(positions, list->size - 2); // push position of OP_JUMP_IF_FALSE to positions stack
				break;
			}
			case 'e': {
				int64_t index = pop_list(positions);

				if (index == -1) {
					fprintf(stderr, "No jump corresponding to end operation.\n");
					break;
				}

				if (list->bcode[list->bcode[index + 1]] == OP_WHILE) {
					append_list(list, OP_JUMP);
					append_list(list, list->bcode[index + 1]);
				}

				append_list(list, OP_END);

				list->bcode[index + 1] = list->size - 1;

				break;
			}
			case '#': {
				int64_t index = pop_list(positions);

				if (index == -1) {
					fprintf(stderr, "No jump corresponding to else operation.\n");
					break;
				}

				append_list(list, OP_JUMP);
				append_list(list, 0);
				append_list(positions, list->size - 2);

				list->bcode[index + 1] = list->size - 2;
				break;
			}
			case 'w': {
				append_list(list, OP_WHILE);
				append_list(positions, list->size - 1);

				break;
			}
			case 'd': {
				append_list(list, OP_JUMP_IF_FALSE);

				int64_t index = pop_list(positions);

				if (index == -1) {
					fprintf(stderr, "No jump corresponding to while loop beginning.\n");
					break;
				}

				append_list(positions, list->size - 1);

				append_list(list, index);
				break;
			}
			case '`': {
				append_list(list, OP_CLEAR);
				break;
			}
			case '1': {
				append_list(list, OP_DEBUG);
				break;
			}
			case '[': {
				append_list(list, OP_LOOPS);
				append_list(positions, list->size - 1);
				break;
			}
			case ']': {
				int64_t index = pop_list(positions);

				if (index == -1) {
					fprintf(stderr, "No loop beginning detected.\n");
					break;
				}
				
				append_list(list, OP_LOOPE);
				append_list(list, index);
				break;
			}
			case '_': {
				append_list(list, OP_EQ);
				break;
			}
			case '~': {
				append_list(list, OP_NOT);
				break;
			}
			case 'g': {
				append_list(list, OP_GT);
				break;
			}
			case 'l': {
				append_list(list, OP_LT);
				break;
			}
			case '@': {
				append_list(list, OP_ALLOC);
				break;
			}
			case '|': {
				append_list(list, OP_WRITE);
				break;
			}
			case '^': {
				append_list(list, OP_READI);
				break;
			}
			case 'f': {
				append_list(list, OP_FREE);
				break;
			}
			case 's': {
				append_list(list, OP_LEN);
				break;
			}
			case 'o': {
				append_list(list, OP_OPENF);
				break;
			}
			case 'r': {
				append_list(list, OP_READF);
				break;
			}
			case 't': {
				append_list(list, OP_WRITEF);
				break;
			}
			case 'c': {
				append_list(list, OP_CLOSEF);
				break;
			}
			default: continue;
		}
	}

	free_list(positions);

	return list;
}

void dump_s_and_t() {
	printf("-- TAPE --\n...");
	for (int i = (tapepos - 5) < 0 ? 0 : (tapepos - 5); i < ((tapepos + 5) > 128 ? 128 : (tapepos + 5)); i++) {
		if (i == tapepos) {
			printf("[");
		}
		printf("%ld,", tape[i]);
		if (i == tapepos) {
			printf("]");
		}
	}
	printf("\b...\n");

	printf("\n-- STACK --\n");
	for (int i = top - 1; i > top - 6; i--) {
		if (i < 0) break;

		printf("(%ld)\n", stack[i]);
	}
	printf("END OF DEBUG INFO\n");
}

_Bool contains(int64_t *elem) {
	for (int i = 0; i < 256; i++) {
		if (allocstack[i] == NULL) return 0;
		if (allocstack[i] == elem) return 1;
	}
	return 0;
}

int64_t indexof(int64_t *ptr) {
	for (int i = 0; i < 256; i++) {
		if (allocstack[i] == NULL) return -1;
		if (allocstack[i] == ptr) return i;
	}
	return -1;
}

void freemem(int64_t *ptr) {
	int64_t index = 0;
	for (int i = 0; i < 256; i++) {
		if (allocstack[i] == NULL) return;
		if (allocstack[i] == ptr) {
			free(allocstack[i]);
			index = i;
			break;
		}
	}

	int64_t final_i = index;
	for (int i = index; i < 256; i++) {
		if (allocstack[i + 1] == NULL) break;
		if (i + 1 >= 256) break;
		int64_t *temp = allocstack[i];
		allocstack[i] = allocstack[i + 1];
		allocstack[i + 1] = temp;

		int64_t tempsize = memsize[i];
		memsize[i] = memsize[i + 1];
		memsize[i + 1] = tempsize;

		final_i = i + 1;
	}

	allocstack[final_i] = NULL;
	memsize[final_i] = 0;
	alloctop--;
}

void run(BytecodeList *bytecode) {
	for (int i = 0; i < bytecode->size; i++) {
		switch (bytecode->bcode[i]) {
			case OP_INCITER: {
				if (tapepos >= 128) {
					fprintf(stderr, "Tape pointer out of bounds.\n");
					return;
				}
				tapepos++;
				break;
			}
			case OP_DECITER: {
				if (tapepos < 0) {
					fprintf(stderr, "Tape pointer out of bounds.\n");
					return;
				}
				tapepos--;
				break;
			}
			case OP_DOLLAR: {
				if (top >= 256) {
					fprintf(stderr, "Stack overflow.\n");
					return;
				}

				stack[top++] = tape[tapepos];
				break;
			}
			case OP_ACCESS: {
				int32_t index = tape[tapepos];
				
				if (index < 0 || index >= 128) {
					fprintf(stderr, "Index out of bounds.\n");
					return;
				}

				stack[top++] = tape[index];
				break;
			}
			case OP_POP: {
				if (top - 1 < 0) {
					fprintf(stderr, "No elements on the stack.\n");
					return;
				}

				tape[tapepos] = stack[--top];
				break;
			}
			case OP_GROW: {
				tape[tapepos]++;
				break;
			}
			case OP_UNGROW: {
				tape[tapepos]--;
				break;
			}
			case OP_ADD: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough operands on stack for add operation.\n");
					return;
				}

				int a = stack[--top];
				int b = stack[--top];

				stack[top++] = a + b;
				break;
			}
			case OP_SUBTR: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough operands on stack for subtract operation.\n");
					return;
				}

				int a = stack[--top];
				int b = stack[--top];

				stack[top++] = b - a;
				break;
			}
			case OP_MULTI: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough operands on stack for multiply operation.\n");
					return;
				}

				int a = stack[--top];
				int b = stack[--top];

				stack[top++] = a * b;
				break;
			}
			case OP_DIV: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough operands on stack for div operation.\n");
					return;
				}

				int a = stack[--top];
				int b = stack[--top];

				stack[top++] = b / a;
				break;
			}
			case OP_MODULO: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough operands on stack for mod operation.\n");
					return;
				}

				int a = stack[--top];
				int b = stack[--top];

				stack[top++] = b % a;
				break;
			}
			case OP_PUTC: {
				putchar(tape[tapepos]);
				break;
			}
			case OP_PUTN: {
				printf("%ld\n", tape[tapepos]);
				break;
			}
			case OP_JUMP_IF_FALSE: {
				if (top - 1 < 0) {
					fprintf(stderr, "Not enough operands on stack for conditional operation.\n");
					return;
				}

				if (stack[--top] == 0) {
					i = bytecode->bcode[i + 1];
				}

				i++;
				continue;
			}
			case OP_JUMP: {
				i = bytecode->bcode[i + 1];
				break;
			}
			case OP_CLEAR: {
				tape[tapepos] = 0;
				break;
			}
			case OP_DEBUG: {
				dump_s_and_t();
				break;
			}
			case OP_LOOPE: {
				if (tape[tapepos] > 0) {
					i = bytecode->bcode[i + 1];
					continue;
				}

				i++;
				continue;
			}
			case OP_EQ: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough arguments for equality check on the stack.\n");
					return;
				}

				int64_t a = stack[--top];
				int64_t b = stack[--top];

				stack[top++] = a == b;
				break;
			}
			case OP_NOT: {
				if (top - 1 < 0) {
					fprintf(stderr, "Not enough arguments for not operation on the stack.\n");
					return;
				}

				int64_t a = stack[--top];

				stack[top++] = (a == 0) ? 1 : 0;
			}
			case OP_GT: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough arguments for greater-than check on the stack.\n");
					return;
				}

				int64_t a = stack[--top];
				int64_t b = stack[--top];

				stack[top++] = b > a;
				break;
			}
			case OP_LT: {
				if (top - 2 < 0) {
					fprintf(stderr, "Not enough arguments for greater-than check on the stack.\n");
					return;
				}

				int64_t a = stack[--top];
				int64_t b = stack[--top];

				stack[top++] = b < a;
				break;
			}
			case OP_ALLOC: {
				if (tape[tapepos] <= 0) {
					fprintf(stderr, "Illegal size of memory to allocate.\n");
				}

				allocstack[alloctop] = malloc(tape[tapepos] * sizeof(int64_t));
				memsize[alloctop] = tape[tapepos];

				tape[tapepos] = (int64_t) allocstack[alloctop];

				alloctop++;
				break;
			}
			case OP_WRITE: {
				if (!contains((int64_t *) tape[tapepos])) {
					fprintf(stderr, "Write to illegal memory address.\n");
					return;
				}

				if (top - 2 < 0) {
					fprintf(stderr, "Not enough arguments on the stack for mem write operation.\n");
					return;
				}

				int64_t *mem = (int64_t *) tape[tapepos];

				int64_t offset = stack[--top];

				if (offset > memsize[indexof(mem)]) {
					fprintf(stderr, "Offset for mem write to is too big.\n");
					return;
				}

				int64_t num = stack[--top];

				mem[offset] = num;
				break;
			}
			case OP_READI: {
				if (!contains((int64_t *) tape[tapepos])) {
					fprintf(stderr, "Read of illegal memory.\n");
					return;
				}

				if (top - 1 < 0) {
					fprintf(stderr, "Not enough arguments on the stack for mem read operation.\n");
					return;
				}

				int64_t *mem = (int64_t *) tape[tapepos];
				int64_t offset = stack[--top];

				if (offset > memsize[indexof(mem)]) {
					fprintf(stderr, "Offset for mem read is too big.\n");
					return;
				}

				stack[top++] = mem[offset];
				break;
			}
			case OP_FREE: {
				if (!contains((int64_t *) tape[tapepos])) {
					fprintf(stderr, "Invalid mem free argument.\n");
					return;
				}

				freemem((int64_t *) tape[tapepos]);
				break;
			}
			case OP_LEN: {
				if (!contains((int64_t *) tape[tapepos])) {
					fprintf(stderr, "Invalid mem len address.\n");
					return;
				}

				stack[top++] = memsize[indexof((int64_t *) tape[tapepos])];
				break;
			}
			case OP_OPENF: {
				// TODO: IMPLEMENT FILE IO
			}
			case OP_LOOPS: continue;
			case OP_WHILE: continue;
			case OP_END: continue;
		}
	}
}
