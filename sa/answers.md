# Clang Static Analyzer



### 3.1

* test.c就是源程序,AST.svg就是根据test.c所做出的抽象语法树,与路径无关的静态分析可以直接在AST上做.CFG.svg即control flow graph,控制流程图,用来表示程序执行时所有可能的执行路径,可由AST作出.ExplodedGraph.svg则与CFG有比较直接的关系,它是对CFG做了扩展,原来CFG中programpoint相同,program state不同的情况都是看做一个节点,但ExplodedGraph把即使program point相同,仅仅是状态不同的节点也看做不同节点.这样画出的图比原CFG节点数更多,相当于把CFG展开了,得到的图就是ExplodedGraph.



### 3.2

* 主要是在CFG上进行的,因为checker进行静态分析时是路径敏感的,而路径等信息都存储在CFG和ExplodedGraph中,只在AST上无法进行路径敏感的静态分析.

* 状态保存在对应的ExplodedGraph中的node里面,每个node包括ProgramPoint和ProgramState.程序状态存在ProgramState中.

* 注:这里我的理解是只有那些真的无法确定的value才被称为symbolic value,也就是SymExpr.Sval指向其他类型的Value没有认为是symbolic value.

  第一行 int x=3, y=4;不会产生 symbolic values. x的memregion bind 到concrete number 3, y bind到4.
  int *p =&x; 会产生\$0,是&x的Sval.
  int z = *(p + 1); 会产生\$1 ,对应(p+1)的Sval.还有\$2,对应\*(p+1)的Sval.
  关系:　p的memregion bind的是\$0,\$1表示的是p+1,相当于是$0与concrete number 1相加的结果.
  而\$2表示的是p+1指向内存单元的内容,即\$1指向内存单元内容.

  简单地用表达式表述即为如下关系:

  \$1=\$0+1

  \$2=*(\$1)



### 3.3

* 用到的智能指针主要有:unique_ptr,shared_ptr,weak_ptr

  unique_ptr是独享所有权的,也就是一个对象同时只能有一个指针指向它.

  shared_ptr是允许共享所有权,也就是可以有多个指针指向同一个对象,这时需要使用引用计数记录有多少个指针指向同一对象.

  weak_ptr是结合shared_ptr使用的一种指针,它同样提供对shared_ptr指向对象的访问,但不参与引用计数.

  如果程序不需要多个指向同一个对象的指针,则可使用unique_ptr,多数情况下会使用这种指针

  如果程序确定要使用多个指向同一个对象的指针,应选择shared_ptr

  如果程序中想要观察一个对象但不保持其活动状态,应使用weak_ptr,事实上weak_ptr也因为其不参与引用计数而常用于打破因shared_ptr产生的循环引用.

* 不使用RTTI的理由是:为了减少代码和可执行文件的size,因为正如C++提倡的原则一样:*“you only pay for what you use”* .而事实上RTTI很多情况下在代码中是用不到的,如果直接采用RTTI会增加很多无用的代码与开销.

  所以LLVM提供了替代机制—它扩展性地使用了一种 hand-rolled(不知道怎么翻译好...) form of RTTI,这种机制使用例如在LLVM Programmer's Manual开头提到的 isa<>,cast<>,dyn_cast<>等template来实现.它与原本的c++ RTTI相比优势主要在于它是opt-in的,而且可以添加到任何class当中.也就是说它是可选的,我们只要在可能需要进行RTTI推断的class中添加RTTI机制,不会用到的就不添加,这样就可以缩减代码量.而且它的推断也比C++自身的RTTI推断更有效率.

* 前者参数声明为llvm::ArrayRef类型,因为ArrayRef可以接收指定大小数组,std::vector, llvm::SmallVector以及其他任何在内存中连续存储的类型.

  后者参数声明为StringRef类型,因为LLVM Programmer's Manual的Passing strings一节明确写明了StringRef类可以接收C风格的字符串或者std::string


* 主要是因为可能多个cpp文件中使用同一个名字作变量或者函数名,为了避免重定义冲突,或者定义的标识符不希望被外部访问,C中的解决方法是用static修饰,使其只能在限定的translation unit中可见.但是C++不提倡使用static,因为C++只提倡用static修饰类成员.所以我们使用匿名命名空间来达到和static修饰同样的效果,来避免外部访问,从而避免重定义冲突等问题.(虽然效果一样但实现不同,static是会修饰标识符的linkage为internal linkage,而匿名命名空间是通过系统自动给每个匿名空间分配一个不同的名字来实现)



### 3.4

* 这个checker对于每个SymbolRef型的对象保存一个定义为StreamState型的状态,StreamState类中保存的状态信息事实上只有这个Stream是打开(Opened)还是关闭(Closed). 整个checker所保存的状态信息是一个key类型为SymbolRef,value类型为StreamState的map.这个map命名为StreamMap,它存储在ProgramState中,利用REGISTER_MAP_WITH_PROGRAMSTATE这个宏来实现,在程序第90行.

* 当fopen成功时,状态会变化,fopen的returnvalue对应SymbolRef在map里的value被set为Opened,然后这时因为整体的程序状态也发生了更新,所以program state增加一个新的transition,即exploded graph上的一条边.

  具体代码见CheckPostCall函数.

  同理,当fclose成功时,也会发生与fopen成功时类似的变化,fclose参数对应的SymbolRef的状态set为Closed.详见CheckPreCall.

  当调用CheckDeadSymbols时,迭代检查时如果发现有symbol是dead的,状态也会发生变化,checker会把这个dead的symbol从StreamMap中移除,以保证状态信息的精简.

  最后还有当调用CheckPointerEscape的时候,如果对应的call可能关闭文件,会把所有的Escaped Symbol从StreamMap中remove掉,不再追踪它们,这样程序状态也会发生改变.

* 当调用fclose函数时要检查状态,此时要检查的是传的参数对应的SymbolRef FileDesc的状态.从StreamMap中查找FileDesc的Value,即它的状态.如果这个StreamState存在且是Closed,说明发生了多次close同一文件的问题,于是要调用reportDoubleClose报告错误.

  isLeaked函数判断symbol是否leak时也要检查状态,不过它检查的不是StreamState,而是从ProgramState得到ConstraintManager,从而来检查symbol是否leak.

* 该函数的逻辑是:首先,因为escape pointers导致的问题是可能使分析器无法确定文件是否是关闭状态,而如果一次调用中不可能关闭文件,则不存在该问题.所以先利用guaranteedNotToCloseFile函数判断一下本次检查针对的Call有没有可能关闭文件,没可能的话就直接返回,程序状态不变. 有可能的话,就简单地认为这些escape的指针会在其他地方被close掉,故把所以escape的指针对应的symbol都从StreamMap中移除,更新程序状态,不再追踪它们.

  实现的功能就是检查函数调用时有没有escape掉的文件指针,有的话就标记这些指针,不再追踪它们对应的symbol状态信息,以免分析时发生无法判断文件是否关闭的问题.

  使用场合是用在调用可能会关闭文件的函数时,来避免因escape pointers带来的问题.

* 这个checker能检查出的bug主要有:

  1. 对已经关闭的文件重复进行fclose操作
  2. 文件打开后没有关闭,可能导致资源泄露(leak)

  测试程序(在gitbook给的实例改编了一下):

  \#include  <stdio.h>

  FILE *open(char *file)
  {
      return fopen(file, "r");
  }

  void f1(FILE *f)
  {
      fclose(f);
  }

  void f2(FILE *f)
  {
      fclose(f);
  }

  void f3(FILE *f)
  {
      f=open("bar");
      fprintf(f,"hello!");
  }

  int main()
  {

      FILE *f = open("foo");
      FILE *p;
      f1(f);
      f2(f);
      f3(p);
      return 0;
  }

  用SimpleStreamChecker检查,生成两个warning如下:

  dblclose.c:15:5: warning: Closing a previously closed file stream

      fclose(f);
      ^~~~~~~~~
  dblclose.c:22:1: warning: Opened file is never closed; potential resource leak
  }
  ^

  ​

  因为这是一个比较简单的checker,局限性非常多,这里举例说明２个:

  1. 缺少对于NULL指针情况的检测,例如下面的代码:

     FILE *p=NULL;

     fclose(p);

     这很明显会产生bug,运行的话会产生段错误,但是这个checker无法检查出来,甚至我用另一个名为StreamChecker的更高级的checker分析也无法检测出来,即使源码中有一个叫CheckNullStream的函数...(没仔细看它怎么实现的)

  2. 当一个函数中同时出现两种上述bug时,这个checker只能检查出其中重复close的bug,resource leak的bug无法检测出,而使用更高级的StreamChecker是两个bug都能检测出的,例如下面代码(f1,f2,open还是之前定义的):

  ​       int main()
  {


```C
  FILE *p=open("foo");
  FILE *f=open("bar");
  fprintf(p,"hi!");
  f1(f);
  f2(f);
  return 0;
```

  }

  使用SimpleStreamChecker的报错信息:

  dblclose.c:15:5: warning: Closing a previously closed file stream

      fclose(f);
      ^~~~~~~~~
  1 warning generated.

  使用StreamChecker的报错信息:

  dblclose.c:15:5: warning: Try to close a file Descriptor already closed. Cause

        undefined behaviour
      fclose(f);
      ^~~~~~~~~
  dblclose.c:24:5: warning: Opened File never closed. Potential Resource leak
      f1(f);
      ^~~~~
  2 warnings generated.




### 3.5

* 要添加的文件是checker的cpp源码文件,加到lib/StaticAnalyzer/Checkers里。

  要修改的文件有:

  1. cpp源码本身,要在最后加入registration code

  2. clang/include/clang/StaticAnalyzer/Checkers/Checkers.td(文档中的路径好像写错了)

     在checkers.td中要加入代码来为这个checker选择正确的package,并把这个checker在checker table中进行定义.

  3. clang/lib/StaticAnalyzer/Checkers/CMakeLists.txt.

     要在其中加入checker的源码文件,使cmake能够找到这个checker.

* 代码如下:

  clang_tablegen(Checkers.inc -gen-clang-sa-checkers
    -I ${CMAKE_CURRENT_SOURCE_DIR}/../../../
    SOURCE Checkers.td
    TARGET ClangSACheckers)

  顾名思义,该函数的作用是生成clang的checker table.这个table最终保存在文件Checkers.inc中(在build中可以找到).以Checkers.td为source,ClangSACheckers作为target.其中的路径参数指明了编译后输出的文件位置.

* 这类文件的作用在于在其中保存check table的信息,所有的checker都集中在其中定义(有一个专用的tablegen语言). 它是利用llvm提供的一个tablegen工具,把.td文件作为source,在CMakeLists.txt的指示下(事实上也可以不用CMake,CMake也是调用的tablegen工具)来生成C++头文件或源文件的.

  这种机制的好处在于批量处理,容易扩展,要加新的checker只要在.td文件中加一些相应的内容,不必做重复的无用工作.cmakelists.txt等其他文件都不需要修改.











