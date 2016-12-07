CLANG=clang
LLC=llc
GCC=gcc
FILES=fib fib-m

all : $(FILES) clean

fib:
	$(CLANG) fib.c -o fib
fib-m.s:
	$(LLC) fib-m.ll -o fib-m.s
fib-m : fib-m.s
	$(GCC) fib-m.s -o fib-m
.PHONY : clean

clean:
	rm -f fib-m.s

