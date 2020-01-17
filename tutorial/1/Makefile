.PHONY: all t1part1

all:
	flex -o expr.lex.cpp expr.lex
	bison -d -o expr.y.cpp expr.y
	clang++ -Wno-implicit-function-declaration -o expr expr.y.cpp expr.lex.cpp -ly

t1part1:
	flex -o expr.lex.cpp expr.lex
	clang++ -Wno-implicit-function-declaration -o expr expr.lex.cpp -ll

clean:
	rm -Rf expr.lex.cpp expr.y.cpp expr.y.hpp *.o expr *~
