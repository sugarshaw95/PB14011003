## 					MP1.2说明



#### 实现的功能：

- 实现了对cool语言正常情况下的基本词法分析,包括：
    - 对cool文件行号的记录,利用curr_lineno变量  
         
    - 对cool定义的关键词的分析,返回对应token
    
    
    - 对于Identifier,integer还有string的分析,同时将对应的三个stringtable填好,
      其中对于string,根据规范要对"\c"类以及\n等作特殊处理,基本思路是用数组string_buf存储记录的string.
    
    - 对其他合法运算符,例如 + - * 等,直接返回该字符.
    
    - 对注释的处理,将注释里的内容全部忽略不作分析.


- 实现了实验要求的错误处理机制,并通过yylval.error_msg返回错误信息,包括：
    - 遇到非法字符(例如>这样的既不在关键词中又不属于cool-parse中定义的其他合法字符的),直接返回error token,并将该字符
    赋给error_msg.从下一个字符开始分析.
    
    - 对于字符串,如果其中包含非法字符(null)或者长度超过了定义的最长长度,需要返回相应的error_msg,但不能立即返回
    error token,要等到遇到右引号",把整个字符串分析完才返回.
    
    - 字符串中若包含非转义换行符,则返回相应错误信息.因为要求是从下一行恢复词法分析,故这种情况立刻返回error token即可,并把
    start condition恢复为initial.
    
    - 对于EOF,无论是字符串还是注释(以--开头且在文件最后一行的除外),都不允许出现,出现时返回相应错误信息(因为EOF后面不会再有
    其他字符,故立即返回error token)
    
    - 在非字符串,非注释的情况下遇到*),需要返回"Unmatched *)"信息,不返回对应的符号token,直接返回error token.


#### 用到的工具和资料:
- 最基本的：cool manual,cool-support tour,flex的手册(参考了其中的例程),flex与bison2015中文版(第一二章,主要也是参考例程)

- 看了用到的cool-support头文件以及make所用到的其他c文件的源码,比如lextest.cc,utilities.cc等.其中有一些关于定义的token
 等内容,是必须看的,否则没办法写代码.
- 用到的工具的话,环境是ubuntu16.04,编码就用的gedit，因为自己之前不怎么用linux,vim试了一下用不惯...我还是喜欢GUI...其他的工
具也没有什么要用到的

####  测试过程

v1.0->v1.01->v1.1->final(add readme.md)

v1.0:对给的测试例可以产生和参考的lexer一样的结果

v1.01:fix a bug,从initial进入str condition时忘了把记录str错误类型的变量重新赋值为0(代表无措)了

v1.1:fix another bug,之前对非转义换行符的处理不正确,没有记录行数.至此将所有类型的错误均测试过了.

final:加上了这个README.md的说明文件