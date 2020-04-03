.PHONY: dce

%.ll:%.bc
	llvm-dis $<
	cat $@

%.o:%.cpp
	clang++ -c `llvm-config --cxxflags` -o $@ $<

%.o:%.bc
	clang++ -c -o$@ $<

dce: dce.o
	clang++ -o$@ $^ `llvm-config --cxxflags --ldflags --libs --system-libs`

clean:
	rm -f dce.o dce *~ main.bc main.ll
