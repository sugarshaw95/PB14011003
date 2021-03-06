## MP1

* 总述

  mp1事实上是分作三个部分:mp1.1,mp1.2和mp1.3.

  mp1.1比较简单,只是做一些环境准备的工作,熟悉一下cool语言特性以及cool-support库代码.

  mp1.2是使用flex,完成一个cool的词法分析器(lexer),生成token序列,并做一些简单的错误处理

  mp1.3则是利用bison完成一个cool的语法分析器(parser),为对应的token序列生成AST,并作简单的错误恢复.

  总的来说,mp1的任务是完成对cool语言分析的一个完整前端(lexer+parser)

* 核心问题&设计&实现

  mp1.1由于是属于阅读实验,就不存在设计等方面的问题了,下面分别针对mp1.2和1.3说明一下:

  * mp1.2

    对于mp1.2,因为使用的工具是flex,所以最核心也是最基本的问题自然是flex的使用.flex文件是分为三部分,用%%分割开,要填充的主要是中间第二部分的内容,在其中定义正则表达式,并写明匹配规则以返回token流.原本的代码已经给出了一个基本框架,可以参照基本框架来完成.在写代码时还要注意理解用到的头文件,cool-parse.h等,其中有很多定义是需要用到的.

    整体的设计思路,首先参考cool-manual第10节词法结构的内容,了解cool的词法元素都有哪些,并为这些词法元素分别定义相应的正规表达式进行匹配,在匹配规则中返回对应的token记号.要处理的主要有int,objid,typeid,string,各种关键字等.同时还要注意识别处理注释和空格,对其只是匹配但不返回.

    另外还要完成的一件事是填充stringtable,因为为了节省空间而设置了stringtable这一机制.其中包括三个table,分别是整型,字符串和标识符的,在分析时还要把这3个table填好.

    在实现时,首先要写出各词法元素的正则表达式,这一点在cool manual中都描述得比较清楚,所以没有太大困难.之后就要对每个正则表达式定义匹配后的动作.首先最基本的是return对应的token值,另外除了各种关键字之外基本都还要有一些其他的操作,比如如果是bool常量要指明值是true还是false,是整形时要填充对应的stringtable,出错时要报错等.这些操作基本都是通过yylval这个变量来实现,这是一个枚举变量,取不同类型的值时可进行不同的操作,这里用到的主要是Symbol,Boolean和error_msg.

    实现时的一个难点是string和comment的分析,这里不能只使用简单的正规表达式匹配,需要用到flex的start condition功能,在gitbook中有说明.事实上这个功能类似于有限状态机,借助它才能完成对string和comment的分析.

    另外还要实现错误处理,实验要求中说明了要处理的错误类型,这里错误处理的基本思路是为错误情况也定义对应的正则表达式去匹配,然后根据错误处理的要求在匹配进行相应操作.

  * mp1.3

    对于mp1.3,其难度相对于1.2有所提升.这次使用的工具是bison,所以最核心和基本的问题与mp1.2类似,就是bison的使用. bison主要是通过定义产生式来定义文法,接受token序列,来进行语法分析,这里在语法分析时要完成的工作就是构建对应的AST.构建AST要使用cool-tree.h,要了解各种节点类的构造方法,层次关系和接口,这些内容需要参考cool support手册的第6节.而定义语法时要参考cool manual中的第12节figure1,其中基本详细地给出了cool的语法规则,都是现成的产生式,其中语法的终结符就是词法分析器产生的各种token.

    mp1.3的设计思想:首先,按照cool手册中给出的语法规则,定义正确的文法.之后参照AST各个节点类的构造函数的使用方法,对不同的情况利用对应的构造函数构造对应的AST节点.其中在定义文法时,虽然手册中已经基本给出文法,但事实上自己还是要进行改写,增加一些产生式的,比如表示let型表达式就需要用到自己定义的产生式. 之后还要进行错误恢复,错误恢复的基本思路是利用bison的error关键字,为要恢复的错误情况定义对应的产生式,使用yyerrok等进行错误恢复.

    具体实现时,多数产生式直接按照cool手册写即可,只有let表达式需要自己改写.因为let表达式对应的ast节点就是递归表示的,所以也是通过递归的产生式来分析let表达式.这里我是另外定义了一个非终结符let_sub来表示.另外还要自己改写的就是多个feature,expr等,需要定义类似feature_list这样的非终结符来表示.在构造各ast节点时,只要充分理解构造函数的用法,事实上并不是太困难.

    实现中一个比较主要的问题是移进规约冲突的解决.例如各种算数表达式,使用简单的文法表示的话会有二义性,产生很多冲突.在解决时一个常用的方法是利用bison的优先级机制,即为各个运算符(token)定义优先级和结合性,以此可以很容易地避免大部分冲突.如果优先级解决不了的冲突只能通过修改文法解决,不过在本次实验中并没有遇到需要修改文法解决的冲突.具体来说要处理的冲突主要有两类,一是各种运算符带来的冲突,二是let结构带来的冲突. 第一类利用优先级很好解决,第二类也是利用优先级机制,把 IN的优先级设为最低来解决,这在提交的answers.txt中也有说明.

    实现上最后的问题就是错误恢复,这里也是我感觉最有难度的部分,因为bison的error机制似乎不是很好理解,而如果不能透彻理解的话,就无法为错误情况定义恰当的产生式,也就无法很好地进行错误恢复.基本思路就是利用error为错误情况也定义相应产生式,匹配到时利用yyerrok等函数进行错误恢复.

    ​

    ​


* 遇到的问题&解决对策

  * mp1.2

    1.2中遇到的问题其实不是太大,主要的困难还是在于理解框架代码,这方面是比较耗时间的.对这次实验,一旦能够上手取做了,事实上并没有遇到太大的问题。我也没有遇到真正值得一说的问题,或者也许是时间太久远了忘掉了,总之对于这个实验暂时没有什么值得一提的问题.不过上交后助教的反馈里发现我在定义的时候忘掉了一个运算符,标识符的定义里忘了包含数字,并且在填inttable的时候直接把数字用atoi转成了int,实际上应该不处理.这都是一些小问题,在助教反馈后立即进行了改正.

  * mp1.3

    mp1.3中遇到的问题主要是在于错误恢复上,事实上对于正确的情况,也没有遇到令人印象深刻的值得一体的问题(也或许是想不起来了?).主要的问题都在于如何写出正确的文法,而由于cool手册给出了详细的参考,所以难度不是太大,这里可能值得一说的也就是let表达式的表达了,当时想了一会才想清楚怎么处理,但把文法写出来之后就没有发现什么问题.

    主要遇到的问题在于错误恢复上,因为正如之前所说,要做好错误恢复需要透彻地理解bison的error关键字的用法.但自己当时在做错误恢复时,感觉一直对error的机制似懂非懂,加上时间紧迫,所以为错误恢复写出的产生式也是很不简洁...甚至在ddl快到时还发现有bug,但是已经来不及改了.最后错误恢复几乎就只做了基本的要求,而且甚至基本的要求都没有做好,还有bug.更不要说扩展,几乎就没怎么做... 至于解决的对策,事实上这个问题也不能算完全解决了,当时被这个问题弄得头昏脑涨,push掉之后简直一眼都不想再看了...如果说要解决的话,也只能是认认真真看相关的文档说明了,把error的机制搞清楚了

* 参考文献

  flex与bison中文版

  cool manual 以及A Tour of the Cool Support Code

  bison和flex的官方手册

  以及不计其数的网上各种博客文章...(csdn之类的)



## MP2

- 总述

  mp2要完成的任务是利用mp1中parser生成的AST,为cool的一个简单语言子集(仅能表示仅由单个名为Main.main()的无参函数组成的 Cool 程序,需要实现的类只有Int和Bool)实现一个llvm的中间代码(IR)的生成器,.

- 核心问题&设计&实现

  这里的核心问题是:理解代码生成器的实现方法(或者说是机制).本次实验的实现方式是:将代码生成分为两遍, 即所提供的框架代码中采用的方法. 第一遍确定每个类的对象内存布局, 即用哪些 LLVM 数据类型来创建每个类、并为程序中出现的所有常量生成 LLVM 常量. 第二遍利用第一遍得到的信息递归地遍历程序中的每种结构特征，为每个表达式生成 LLVM 代码. 为了理解这个过程是如何进行的,需要详细阅读框架代码并理解,另外mp2的README文件也对该过程有一个描述,阅读该文件对理解这个也有帮助.因为框架代码的代码量就已经不小,所以这是一个比较大的工作量.除了阅读cgen.cc,cgen.h等外,生成IR时还要用到valueprinter,operand这两个库,所以也要阅读理解这两个库的用法.总的来说,最核心的问题就是阅读理解框架代码和所使用的库的用法.一旦理解了框架之后,上手写代码就比较快了.

  设计上,按照实验说明,mp2要填充的代码主要是在second pass(事实上我甚至不确定first pass对mp2需不需要加代码,因为似乎按照README的说法first pass要layout features,但mp2要处理的语言子集中没有feature...　反正我最后并没有对first pass调用的函数加代码,似乎也能成功生成和ref相同的IR代码).

  根据框架代码,second pass调用CgenTable的函数code_module().code_module中首先找到Main这个类对应的CgenNode,然后对其调用codeGenMainmain(),生成Main的方法Main_main的代码,之后再调用code_main(),定义全局变量字符串,再定义main函数,该函数调用printf打印Main_main的返回值输出到屏幕.

  对于codeGenMainmain(),它生成代码的过程是这样的,首先设置环境CgenEnvirnoment,这个类保存了当前的环境信息,主要有一些临时变量和标签的计数值,以及一个Symbol到operand的表Symbol table,用来为Object寻找其在内存中对应的位置.　之后,得到Main类的main方法对应的method节点,调用它的code方法,以生成的环境为参数,来生成Main_main的代码.

  对于code方法的说明:

  cool-tree.handcode中为各种AST节点类都定义了虚函数code,参数是一个CgenEnvirnoment,用来生成这个节点对应的代码.本次实验中涉及到的只是method节点的code方法和各种expr节点的code方法. method的code方法是一个void函数,而各种expr因为要有对应的值,所以其code方法都是operand型,但在执行过程中也要生成对应的IR代码.

  综上,我们在cgen.cc中要填充的函数主要有:

  codeGenMainmain(),code_main(),以及method节点和各种expr节点的code方法.其中最重要的是各种AST节点的code方法的填充l.因为事实上main函数的代码是固定的,比较容易写,codeGenMainmain()本身也不生成代码,只是设置一下环境,重点都在于各种AST节点的code方法,归根结底代码主要是通过这些方法生成的.

  实现上,首先解决的是比较简单的code_main(),因为它的内容是确定的.在充分理解ValuePrinter的用法后,很容易就能写出其对应的代码.之后是按照实验说明上的实验攻略给的策略依次实现的:

  先填充method的code方法,这里首先根据method_class包含的成员信息,得到对应的类名和方法名,就知道函数的整体名字,再得到参数的类型(这里先没有写相关代码,因为Main_main确定是无参的,暂时不用写),就得到define这个函数需要的全部信息.之后首先define这个函数,然后设置一个entry,再设置abort函数的入口以处理异常,最后结束定义即可.

  之后处理各种expr,首先是Int_const和bool_const,这两种情况最简单,并不需要生成代码,只需要构造对应的operand(int_value或者bool_value),返回即可.

  之后为了方便测试,实现block. block的code方法是把block中的所有expr的code方法全部执行一遍,最后返回的是最后一个expr的值.

  之后实现各种一元二元运算型expr,比如加减乘除,<,~,not等.这些expr对应的代码也都比较简单,一般就是一两条指令,比如+就是add,取反就是0减操作数等.

  然后是object,对应的指令是从env的symboltable中根据节点中包含的名字找到这个obj在内存中对应的位置,然后load.

  然后是赋值语句,对应的操作是先执行RHS的code方法得到右操作数,再从env中找到LHS对应的operand,最后生成一条store指令.

  然后按照实验指南实现let,这里let比较复杂,是递归实现的,首先对变量定义赋值的操作是先为变量alloca一个内存位置,然后和赋值语句类似进行赋值,其中注意如果变量只定义没有指定初始值,要有一个默认的初始值.之后就执行body的code方法,最后的值是body的返回值.另外注意let对 env有操作,定义变量时,要把这个变量的名字和为其申请的内存位置关系加到env中,使用add_local方法,最后退出方法时,因为是局部变量,又要kill_local.

  最后生成loop和cond.cond表达式的类型与if_exp和else_exp的类型一致,首先执行判断条件expr,用有条件br指令判断条件是否成立,之后分别设置true label和false label,true就跳到true_label执行对应expr,false同理.最后都跳转到end_label. 返回值就是两个expr之一.   loop的原理与cond类似,执行code方法得到cond的值,标记判断的位置为loop.n,判断,true就跳转到true.n,执行expr,然后无条件跳转回loop.n. false则跳转到false.n,继续顺序执行下面的代码.最后的返回值根据实验说明就是整数0,与表达式内容无关.

  最后的最后是错误检验,这里只是除0检验,所以只是对div表达式,用icmp把除数和0比较,相等就跳转到abort,不等跳转到ok.n继续执行.

- 遇到的问题&解决对策

  这里遇到的一个值得一提的问题是处理cond表达式时如何在不生成代码的情况下得到if_exp和else_exp的类型.起初我并不没有发现expression类也有一个get_type方法可以返回Symbol型的类型,所以当时为这个问题想了好久,最后采取的方法是把env的输出流换成一个临时流,之后执行一次code方法来获得类型.为此,还要能够让env恢复以前的状态,所以还定义了几个方法用来恢复状态.后来测试时偶然发现了ref是用expression的get_type方法进行判断,就改成了用这种方法判断,并增加了错误检查,如果前后表达式类型不一致,则输出错误提示信息并abort.

- 参考文献

  LLVM IR官方文档,另外基本就是实验说明和所给的框架代码了,并没有参考太多外部的东西...

