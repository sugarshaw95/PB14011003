# Clang Static Analyzer



### 3.1

* test.c就是源程序,AST.svg就是根据test.c所做出的抽象语法树.CFG.svg即control flow graph,控制流程图,用来表示程序执行时所有可能的执行路径,可由AST作出.ExplodedGraph.svg则与CFG有比较直接的关系,它是对CFG做了扩展,原来CFG中programpoint相同,program state不同的情况都是看做一个节点,但ExplodedGraph把即使program point相同,仅仅是状态不同的节点也看做不同节点.这样画出的图比原CFG节点数更多,这种图就是ExplodedGraph.



### 3.2

* 主要是在AST上进行的,因为语法层次上的报错直接在AST上做即可,与控制流程等有关的检查虽然需要用到CFG,

  但CFG也是要根据AST构造出来.

* 状态保存在对应的ExplodedGraph中的node里面,每个node包括ProgramPoint和ProgramState.程序状态存在ProgramState中.

* 第一行 int x=3, y=4;不会产生 symbolic values. x的memregion bind 到concrete number 3, y bind到4.
  int *p =&x; 会产生\$0,是&x的Sval.
  int z = *(p + 1); 会产生\$1 ,对应(p+1)的Sval.还有\$2,对应\*(p+1)的Sval.
  关系:　p的memregion bind的是\$0,\$1表示的是p+1,相当于是$0与concrete number 1相加的结果.
  而\$2表示的是p+1指向内存单元的内容,即\$1指向内存单元内容.

  简单地用表达式表述即为如下关系:

  \$1=\$0+1

  \$2=*(\$1)



### 3.3

* 用到的智能指针主要有:
* s
* s
* s







### 3.4

* s
* s
* s



### 3.5

* 要添加的文件是checker的cpp源码文件,加到lib/StaticAnalyzer/Checkers里。

  要修改的文件有:

  1. cpp源码本身,要在最后加入registration code

  2. clang/include/clang/StaticAnalyzer/Checkers/Checkers.td(文档中的路径好像写错了)

     在checkers.td中要加入为这个checker选择正确的package,把这个checker在checker table中定义的代码

  3. clang/lib/StaticAnalyzer/Checkers/CMakeLists.txt.

     要在其中加入checker的源码文件,使cmake能够找到这个checker.

* s

* s

* s











