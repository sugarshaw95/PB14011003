declare i32 @strcmp(i8*, i8*)
declare i32 @printf(i8*, ...)
declare void @abort()
declare i8* @malloc(i32)
define i32 @Main_main() {

entry:
	%tmp.0 = alloca i32
	store i32 0, i32* %tmp.0
	%tmp.1 = alloca i32
	store i32 0, i32* %tmp.1
	%tmp.2 = alloca i32
	br i1 true, label %true.0, label %false.0

true.0:
	%tmp.3 = load i32, i32* %tmp.0
	store i32 %tmp.3, i32* %tmp.2
	br label %end.0

false.0:
	%tmp.4 = load i32, i32* %tmp.1
	store i32 %tmp.4, i32* %tmp.2
	br label %end.0

end.0:
	%tmp.5 = load i32, i32* %tmp.2
	%tmp.6 = load i32, i32* %tmp.1
	%tmp.7 = load i32, i32* %tmp.0
	%tmp.8 = icmp eq i32 %tmp.7, 0
	br i1 %tmp.8, label %abort, label %ok.0

ok.0:
	%tmp.9 = sdiv i32 %tmp.6, %tmp.7
	%tmp.10 = load i32, i32* %tmp.0
	%tmp.11 = load i32, i32* %tmp.1
	%tmp.12 = mul i32 %tmp.10, %tmp.11
	%tmp.13 = alloca i32
	store i32 2, i32* %tmp.13
	%tmp.14 = alloca i1
	store i1 false, i1* %tmp.14
	%tmp.15 = alloca i32
	store i32 0, i32* %tmp.15
	%tmp.16 = alloca i1
	store i1 false, i1* %tmp.16
	%tmp.17 = alloca i32
	store i32 4, i32* %tmp.17
	%tmp.18 = alloca i1
	store i1 false, i1* %tmp.18
	%tmp.19 = load i32, i32* %tmp.15
	%tmp.20 = load i32, i32* %tmp.13
	%tmp.21 = icmp eq i32 %tmp.20, 0
	br i1 %tmp.21, label %abort, label %ok.1

ok.1:
	%tmp.22 = sdiv i32 %tmp.19, %tmp.20
	%tmp.23 = alloca i32
	%tmp.24 = load i32, i32* %tmp.13
	%tmp.25 = icmp sle i32 %tmp.24, 4
	br i1 %tmp.25, label %true.1, label %false.1

true.1:
	%tmp.26 = load i32, i32* %tmp.13
	%tmp.27 = add i32 %tmp.26, 2
	store i32 %tmp.27, i32* %tmp.13
	store i32 %tmp.27, i32* %tmp.23
	br label %end.1

false.1:
	%tmp.28 = load i32, i32* %tmp.15
	%tmp.29 = sub i32 0, %tmp.28
	store i32 %tmp.29, i32* %tmp.15
	store i32 %tmp.29, i32* %tmp.23
	br label %end.1

end.1:
	%tmp.30 = load i32, i32* %tmp.23
	br label %loop.2

loop.2:
	%tmp.31 = load i32, i32* %tmp.13
	%tmp.32 = load i32, i32* %tmp.15
	%tmp.33 = icmp slt i32 %tmp.31, %tmp.32
	br i1 %tmp.33, label %true.2, label %false.2

true.2:
	%tmp.34 = load i32, i32* %tmp.13
	%tmp.35 = add i32 %tmp.34, 1
	store i32 %tmp.35, i32* %tmp.13
	br label %loop.2

false.2:
	br label %loop.3

loop.3:
	%tmp.36 = load i1, i1* %tmp.14
	br i1 %tmp.36, label %true.3, label %false.3

true.3:
	%tmp.37 = load i1, i1* %tmp.14
	%tmp.38 = xor i1 %tmp.37, true
	store i1 %tmp.38, i1* %tmp.14
	br label %loop.3

false.3:
	%tmp.39 = alloca i1
	%tmp.40 = load i32, i32* %tmp.17
	%tmp.41 = icmp eq i32 %tmp.40, 3
	br i1 %tmp.41, label %true.4, label %false.4

true.4:
	store i1 true, i1* %tmp.18
	store i1 true, i1* %tmp.39
	br label %end.4

false.4:
	%tmp.42 = load i1, i1* %tmp.16
	store i1 %tmp.42, i1* %tmp.18
	store i1 %tmp.42, i1* %tmp.39
	br label %end.4

end.4:
	%tmp.43 = load i1, i1* %tmp.39
	ret i32 3

abort:
	call void @abort(  )
	unreachable
}

@main.printout.str = constant [25 x i8] c"Main.main() returned %d\0A\00"
define i32 @main() {

entry:
	%tpm.0 = call i32 @Main_main(  )
	%tpm.1 = getelementptr [25 x i8], [25 x i8]* @main.printout.str, i32 0, i32 0
	%tpm.2 = call i32(i8*, ... ) @printf( i8* %tpm.1, i32 %tpm.0 )
	ret i32 0
}

