class Main {
  main(): Int {
	{
	let x:Int,z:Int in 
	{
	if true then x else z fi;
	z/x;
	(x*z);
	};
	let x:Int <-2,y:Bool ,z:Int,t:Bool in let h:Int <-4, p:Bool in 
	{
	z/x;
	if x<=4 then x<-x+2 else z<-~z fi;
	while x<z loop x<-x+1 pool;
	while y loop y<- not y pool;
	if h=3 then p<-true else p<-t fi;
	3;
	};
	}
  };
};
