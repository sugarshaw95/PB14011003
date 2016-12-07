; ModuleID = 'fib.c'
source_filename = "fib.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @fib(i32 %n) #0 {
entry:
  %n.addr = alloca i32, align 4
  store i32 %n, i32* %n.addr, align 4
  %0 = load i32, i32* %n.addr, align 4
  %tobool1 = icmp eq i32 %0,0
  br i1 %tobool1, label %cond.true1,label %cond.false1 ;1st judge
cond.true1:
  br label %end

cond.false1:
  %tobool2 = icmp eq i32 %0,1
  br i1 %tobool2, label %cond.true2,label %cond.false2 ;2nd judge

cond.true2:
  br label %end2  

cond.false2:
  %sub = sub nsw i32 %0, 2
  %call = call i32 @fib(i32 %sub)
  %sub2 = sub nsw i32 %0, 1
  %call2 = call i32 @fib(i32 %sub2)
  %sum = add nsw i32 %call, %call2
  br label %end2

end2:
  %retval2=phi i32 [1,%cond.true2],[%sum,%cond.false2]
  br label %end
end:
  %retval=phi i32 [0,%cond.true1],[%retval2,%end2]
  ret i32 %retval




}

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  %argc.addr = alloca i32, align 4
  %argv.addr = alloca i8**, align 8
  store i32 %argc, i32* %argc.addr, align 4
  store i8** %argv, i8*** %argv.addr, align 8 ;store para
  %0 = load i8**, i8*** %argv.addr, align 8
  %arrayidx = getelementptr inbounds i8*, i8** %0, i64 1
  %1 = load i8*, i8** %arrayidx, align 8 ;get argv[1]
  %call1 = call i32 @atoi(i8* %1) 
  %call2 = call i32 @fib(i32 %call1)
  %call3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %call2)
  ret i32 0
}


declare i32 @printf(i8*, ...) #1

; Function Attrs: nounwind readonly
declare i32 @atoi(i8*) #2

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readonly "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

;这一大串attributes后面的都还不是完全清楚用途...包括atoi的attributes也是写了个例子把特性粘过来,主要写的是中间的主体部分.



