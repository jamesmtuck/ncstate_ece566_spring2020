

.SUFFIXES: %.c

OBJS =  main.o \
	cmm.y.o  \
	cmm.lex.o \
	list.o \
	symbol.o \
	cmdline.lex.o

.PHONY: tests test all

all: p2

p2: $(OBJS)
	clang++ -g -Wno-implicit-function-declaration -o $@ $(OBJS) `llvm-config --cflags --ldflags --libs` -ly -ll `llvm-config --system-libs`

clean:
	rm -Rf p2 $(OBJS) cmm.y.c cmm.lex.c cmm.y.h cmdline.lex.c out.bc
	make -C ./tests clean

test: tests

tests: p2
	make -C ./tests test

%.o:%.c
	clang -g -c -o $@ $^ `llvm-config --cflags` 

cmdline.lex.c: cmdline.lex
	flex -PCmd -o$@ cmdline.lex 

%.y.c: %.y
	bison -d -o $@ $<

cmm.y.h: cmm.y.c 

%.lex.c: %.lex 
	flex -o$@ $<

list.c: list.h

symbol.c:symbol.h uthash.h

%:%.o
%:%.c
