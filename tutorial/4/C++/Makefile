.PHONY: t4

%.ll:%.bc
	llvm-dis $<
	cat $@

%.o:%.cpp
	clang++ -c `llvm-config --cxxflags` -o $@ $<

%.o:%.bc
	clang++ -c -o$@ $<

t4: t4.o
	clang++ -o$@ $^ `llvm-config --cxxflags --ldflags --libs --system-libs`

test:
	clang -O0 -emit-llvm -o tmp.bc tmp.c
	./t4 ./tmp.bc
	llvm-dis tmp.bc

clean:
	rm -f t4.o t4 *~ main.bc main.ll
