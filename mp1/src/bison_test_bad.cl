
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)

class B {
fun():Int {


{

1;
-;
+; -- {}中表达式出错
3;


}

};


};



(* no error *)
class A {
fun():Int {

let x:int <- 1,m:Int <= 2 in 1

};


};

(* error:  b is not a type identifier *)
Class b inherits A {
    F : Int<-1;

};

(* error:  a is not a type identifier *)
Class C inherits A {
fun():Int {
1+ --+号缺失
};

};

(* error:  keyword inherits is misspelled *)
Class D inherts A {
};

(* error:  closing brace is missing *)
Class E inherits A {
;

