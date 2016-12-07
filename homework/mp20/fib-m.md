

### 遇到的问题

主要的问题在于phi,getelementptr这两个指令的使用上,另外还有printf等外部函数的书写.

phi指令按照文档的说法是用来实现SSA graph中的φ node是用来表示这个函数的.事实上我们只要知道它的语法形式是　<result> = phi <ty> [ <val0>, <label0>], ...　这样.这里都是在 a? b:c 型表达式中用到,所以都是两组参数,分别对应a为真和a为假时,两组标签即为真和假时对应标签,值即为真和假时对应的值.该指令很适用于存储a? b:c 型表达式的值,主要参考的是ternary.ll.

getelementptr则是寻址指令,本程序中为了得到arvg[1],要对这个元素进行寻址,寻址就要用到该指令.其语法为:

```
<result> = getelementptr <ty>, <ty>* <ptrval>{, [inrange] <ty> <idx>}*
<result> = getelementptr inbounds <ty>, <ty>* <ptrval>{, [inrange] <ty> <idx>}*
<result> = getelementptr <ty>, <ptr vector> <ptrval>, [inrange] <vector index type> <idx>
```

其中这里用到的是inbounds型,加了inbounds关键字可起保护作用,如果越界的话表达式值是一个"poison value".

参考例子中的getelementptr 的写法,基本就是第一个参数声明类型,第二个参数指定要计算的对象,之后的至少1个参数来指定具体计算哪个元素的地址.

至于printf等外部函数的书写,只要用declare关键字声明一下,然后在调用时也用call指令调用即可.



### 翻译中比较重要的部分

个人感觉翻译中比较重要的部分还是在于对各个指令的理解和使用,尤其是那些和汇编没有什么相似点的指令.像add,mul这样的运算指令,还有br,icmp等和控制有关的指令,都和汇编很像,也比较容易理解,但像之前说的那两个指令,就和汇编没有什么相似点,需要自己多去理解体会.

另外的一点就是翻译中要注意到用前端生成的IR其实是可以精简的,有很多这样的例子,比如例子中的IR代码在main函数中一定会定义一个变量@retval,但很多时候这个变量却用不到,返回值是其他变量.再比如有时一个参数被使用多次的话,前段生成的IR会每次都定义一个新变量,根据这个参数的地址load一遍去取它的值,事实上这是没有必要的.我后来对比了手工翻译的IR和前端生成的结果,确实存在这一问题.
