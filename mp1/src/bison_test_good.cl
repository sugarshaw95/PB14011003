class A {
fun():Int {
1
};
};

Class BB__ inherits A {
};

class B inherits A {
    foo():Int {
        case new SELF_TYPE of
        x:A => 1;
        y:C => 2; 
        z:B => 3;
        esac --分支
    };
};

class Silly {
            copy() : SELF_TYPE { self };
        };
-- SELF_TYPE
class Sally inherits Silly { };


class Main inherits IO {
		z : Bool;
		b : B;
		x : Sally <- (new Sally).copy();
            main() : SELF_TYPE {
            {

		
                let x:Int <- 1,m:Int <- 2 in
                {
                    let y:Int <- 2 in
		  {
                    out_int(x+y);
		   z <- ISVOID(x); --isvoid表达式
		   };	
                }; --嵌套let,isvoid
                out_string("\n");
		NEW Int; --NEW表达式
		if b.foo() then 1 else 0 fi; --if-else-then还有dispatch 
		if b@A.foo() then 1 else 0 fi; --静态dispatch
		let h:Int <-1 in (if b.foo() then 1 else 0 fi);
		x ;
		1+2;
		1-2;
		1*2;
		1/2;
		~1;
		1<2;
		1<=2;
		1=1;
		NOT 1;
		"abc";
		true;	--各种简单表达式

             }
		
            };

            func(n:Int) : Int {
            {
                let sum:Int <- 1 in
                {
                    while 0 < n loop
                    {
                        sum <- sum * n;
                        n <- n - 1;
                    }
                    pool; --循环
                    sum;
                };
            }
            };
        };
