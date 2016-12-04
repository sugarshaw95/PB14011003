## 扩展

* 现有clang静态分析器的一些其他缺陷:

  1. 缺少对windows API check的支持.
  2. 当数组大小为一个变量,而该变量被赋值为负值时,无法检测出bug
  3. 对字符串做一些操作时,有可能出现参数不合法问题,例如strcpy函数的接受字符串size可能小于源字符串,导致无法全部copy,这种bug也无法检测.
  4. 对一些经常使用的标准库函数,分析时对其的模拟和普通的定义未知的函数相同,模拟的程度不够精细.

  缺陷事实上肯定还有很多,不止以上几个,这里只是选了几个比较有代表性的作为例子.

  ​

下面从提供的可选缺陷中选择了2个(unix.API和cplusplus.NewDelete)分别进行具体分析:

* 对unix.API这个checker所对应的缺陷检查而言:

  1. 显然是可以检查unix常用的几个API是否具有缺陷的.检查的函数包括open,pthread_once,calloc,malloc,realloc,alloca,__builtin_alloca,valloc.

  2. 检查的能力:
     对于open函数,能够检测出以下几种bug:

     1.函数参数不合法(参数个数不是２或３,第３个参数类型不是int)

     2.在O_creat位被置１的情况下没有第三个参数

     目前发现的对open函数检查的一个问题是,顺序对同一个文件以相同打开方式调用open多次的话,并不会报warning,这个虽然算不上bug,但也是无效的应当优化的写法,感觉应当报一下warning为好.

     ​

     对于pthread_once函数实现以下检查:

     1.最基本的参数个数问题

     2.检查首个参数使用的是否是从stack中分配的memory或者是局部变量,如果是二者之一的话,报告一个warning,提醒这样的内存使用是危险的,有可能造成问题.并且在必要时提醒程序员是否忘记加"static"

     对于pthread_once,目前没有发现太明显的检查缺陷...

     ​

     对于其余的calloc,malloc,realloc,alloca,__builtin_alloca,valloc这些函数,事实上都是属于内存分配函数,这里需要check的就是函数参数中表示分配空间大小的参数是否为0.如果是0的就要报warning提示:Call to 'xxx' has an allocation size of 0 bytes.

     对于这些函数,一个很明显的缺陷在于,这个checker只检查了0却没有检查负数的情况.虽然经验证,如果在程序中写了分配空间大小为负数的语句,在之后使用相应变量时分析器会报告说这个值是garbage,但这种明显的错误不应该在使用时才报,而且这个warning也不是unix.API这个checker给出的,因为我们如果只malloc一个大小为负数的空间,然后再删除而不使用,用这个checker分析不会报任何错.所以这是一个比较打的缺陷.

  3. 实现的机制上,open函数使用check_open函数检查,该函数首先检查参数个数是否合法,之后若有第三个参数,检查其类型是否为int.之后依次得到O_CREAT的值,检查oflags是否设置成O_CREAT,maskedFlags是否非0等,最后检查O_CREAT被置１情况下是否缺少第３个参数.

     pthread_once函数的检查利用CheckPthreadOnce函数,因为只检测一种bug,该函数逻辑很简单,只要检查第一个参数是不是从stack分配的或者是不是局部变量,是的话报warning即可.

     对于其余几种内存分配的相关函数,除了calloc,都是只有一个与分配空间大小有关的参数,所以这些函数统一调用同一个函数检查即可,只是因为总参数个数的区别传的参数不同.这个统一的函数为BasicAllocationCheck,它实现的功能就是根据传递的参数,检查参数列表中最后一个参数(代表分配的空间大小)是否为0,是0的话就报告warning.   而calloc与其他函数不同,因为它的两个参数都代表分配空间的大小,都需要检查是否为0,所以它有一个单独的检查函数CheckCallocZero,但这个函数与BasicAllocationCheck的代码结构基本一致,只是在对于参数检查的部分从只检查最后一个变成了检查所有的参数(事实上也只有２个,不过还是用了一个循环...)

     具体的源码位置:所有代码都在UnixAPIChecker.cpp中,open的检查函数在第91行,pthread_once第168行,BasicAllocationCheck和CheckCallocZero分别在255和284行.具体代码因为比较长,而且感觉粘代码也很蠢没什么必要,就不粘了...

  4. open的问题不是很好分析,而且那个也不一定能被称为"问题",这里就不分析了,但内存分配大小为负数的问题很好分析,就是源码的check函数中本身就只考虑了0的情况而没有考虑负数的情况,将非0情况一视同仁处理造成的.

  5. 上问题想要改进的话思路应该比较简单,就是判断完是否为0后还要判断一下是不是负数,如果是负数也要报warning.但这只是一个基本思路,因为在分析时判断value是否为负数的方法如何实现我也不是很清楚...

     ​

* 对于cplusplus.NewDelete:

  1. 可以检查出double delete以及use-after-delete两种bug

  2. 检查的能力:

     当上述两种bug在同一个函数内只出现一种且一次时,能够正确检测出所有的bug.但当同一个函数内不止一次出现bug时,静态分析器只能检测出最先发现的那个bug,之后的其他bug会被忽略,这是一个比较大的缺陷.

  3. 检察实现机制:

     对于double delete的检查,实现机制比较简单,就是在每次delete时调用checkdoubledelete函数检查,该函数逻辑就是看一下delete的对象是否已经release,如果已经realease就出现bug,源码如下(在MallocChecker.cpp中):

     bool MallocChecker::checkDoubleDelete(SymbolRef Sym, CheckerContext &C) const {

       if (isReleased(Sym, C)) {
         ReportDoubleDelete(C, Sym);
         return true;
       }
       return false;
     }

     对于use-after-delete的检查,机制很简单,每次用到变量时调用相应函数check即可,check函数结构也很简单,如下:

     bool MallocChecker::checkUseAfterFree(SymbolRef Sym, CheckerContext &C,                                  const Stmt *S) const {


       if (isReleased(Sym, C)) {
         ReportUseAfterFree(C, S->getSourceRange(), Sym);
         return true;
       }

       return false;
     }

     只要看一下sym是否已经被释放,如果被释放说明出现bug,否则没有出现.

     而判断两者都用到的判断是否释放的代码也很简单,检查一下对应的RefState里保存的K是不是released即可.如下(见源文件2292行):

     bool MallocChecker::isReleased(SymbolRef Sym, CheckerContext &C) const {
       assert(Sym);
       const RefState *RS = C.getState()->get<RegionState>(Sym);
       return (RS && RS->isReleased());
     }

     以上两个check函数的调用时机为:在调用一个函数前调用checkPreCall,在其中检查调用的是否为delete，是的话调用checkdoubleDelete检查.在使用一个stmt前后,即在PreStmt和PostStmt中都调用CheckUseAfterUse检查.

  4. 这里简单分析一下出现这种多个bug只能检测出第一个的原因,事实上我也没有分析出根本的原因,只是从设计模式上类比了一下.因为事实上这里检测的bug类型和SimpleStreamChecker是非常相似的,而SimpleStreamChecker同样存在这一问题.而我注意到对于StreamChecker却不存在这样的问题.而Simple~和StreamChecker的源码设计上一个很大的区别就是Simple的checker是使用PostCall,PreCall这样的函数,在调用前后进行判断分析检查bug.而StreamChecker则是使用一个evalCall函数,对每次Call统一分类处理,而不是分成PreCall,PostCall等情形.而结果是StreamChecker没有出现只能分析出一个bug的问题.而这里的new delete相关的check机制也是和SimpleChecker类似地分为PreCall,PostCall这样的模式,结果也出现了和SimpleStreamChecker一样的问题.　所以我猜想这个问题可能是和代码设计的模式有关的,像SimpleStreamChecker那样的结构的代码可能都会有这个问题. 但是这也只是猜测,因为虽然我尽力读了源码,但确实代码量有点多,时间也有限,所以我并没有真正弄明白这样的设计模式为何会导致这种问题...

     `

     ​



