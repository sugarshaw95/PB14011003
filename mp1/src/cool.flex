/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include<stdlib.h>
/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int str_error_type=0;// 记录string中的error type

int comment_type=0;//表示comment的类型(按以(*还是--开头区分),0是(*型,1是--型
int num=0;//记录注释中共嵌套的(*个数
%}

%option noyywrap



%x comment
%x str   

/* define start conditions for string and comments */



/*
 * Define names for regular expressions here.
 */

class (?i:class)
else (?i:else) 
fi (?i:fi) 
if (?i:if) 
in (?i:in)
inherits (?i:inherits)
let (?i:let) 
loop (?i:loop)
pool (?i:pool)
then (?i:then)
while (?i:while) 
case (?i:case)
esac (?i:esac) 
of (?i:of)
isvoid (?i:isvoid)
new (?i:new)
not (?i:not)
false f(?i:alse)
true t(?i:rue) 
darrow =>  
assign <-
LE <=
signs "+"|"/"|"-"|"*"|"="|"<"|"."|"~"|","|";"|":"|"("|")"|"@"|"{"|"}" 
int  [0-9]+
typid [A-Z][a-zA-Z0-9_]*
objid [a-z][a-zA-Z0-9_]*
digit       [0-9]

%%



 /*INITIAL condition */
<INITIAL>{
\" {string_buf_ptr=string_buf;str_error_type=0;BEGIN(str);}
  /* if string,v1.01修改的这里,之前忘了把str_error_type改回0*/

"*)"   {yylval.error_msg="Unmatched *)";return ERROR;}
  /* if *) ,error */

--  {comment_type=1;BEGIN(comment);}
"(*"   {comment_type=0;num=1;BEGIN(comment);}
  /* 两种可能的注释开始情况 */


{class} {return CLASS;}
{else} {return ELSE;}
{fi} {return FI;}
{if} {return IF;}
{in} {return IN;}
{inherits} {return INHERITS;}
{let} {return LET;}
{loop} {return LOOP;}
{pool} {return POOL;}
{then} {return THEN;}
{while} {return WHILE;}
{case} {return CASE;}
{esac} {return ESAC;}
{of} {return OF;}
{isvoid} {return ISVOID;}
{new} {return NEW;}
{not} {return NOT;}
{darrow} {return DARROW;}
{LE} {return LE;}
{assign} {return ASSIGN;}
<<EOF>> {return 0;}
 /*all the normal keywords */

{false} {
yylval.boolean=0;	
return BOOL_CONST;
}
{true} {
yylval.boolean=1;
return BOOL_CONST;
}
 /*bool type */

\n	{curr_lineno++;}
" "|\f|\r|\t|\v {}
 /*white space&count lines */

{int} {

yylval.symbol=inttable.add_string(yytext);
return INT_CONST;
}

{typid} {
yylval.symbol=idtable.add_string(yytext);
return 	TYPEID;
}

{objid} {
yylval.symbol=idtable.add_string(yytext);
return OBJECTID;
}
 /*int&id */
{signs} {
return(*yytext);
}
 /*other signs like + - ... */

. {
yylval.error_msg=yytext;
return ERROR;
}
 /*invalid chars,return error */
}



 /*str conditon,处理string */
<str>{
\"  { 
*string_buf_ptr='\0';
BEGIN(INITIAL);
if(strlen(string_buf)>MAX_STR_CONST)
str_error_type=2;
switch(str_error_type){
case 0:   yylval.symbol=stringtable.add_string(string_buf);  return(STR_CONST); break;
case 1:  yylval.error_msg="String contains null character"; return ERROR; break;
case 2:  yylval.error_msg="String constant too long"; return ERROR; break;
} /*结束情况 */
}

\\\n {curr_lineno++;*string_buf_ptr++='\n';}

 /*对应转义的换行符情况,在v1.1中fix,原来有Bug */ 
          
\n {
curr_lineno++;
yylval.error_msg="Unterminated string constant";
BEGIN(INITIAL);
return ERROR;
} //字符串里遇到\n直接报错,从下一行重新开始分析

\\n *string_buf_ptr++='\n';
\\b *string_buf_ptr++='\b';
\\t *string_buf_ptr++='\t';
\\f *string_buf_ptr++='\f';
 /*四种特殊转义字符 */



\0 {
str_error_type=1;
} //null character错误

<<EOF>> {
BEGIN(INITIAL);
yylval.error_msg="EOF in string constant"; 
return ERROR;

} //eof错误


\\[^nbtf] {
*string_buf_ptr++=yytext[1];
} 
 /*一般转义字符 */
[^\\\n\"]+ {
char *yptr = yytext;
while ( *yptr )
{
*string_buf_ptr++ = *yptr++;
}
}
 /*其他情况,直接记录到string_buf里*/
}



 /*comment condition,处理注释 */
<comment>{
\n {
curr_lineno++;
if(comment_type==1)
{
BEGIN(INITIAL);
}
}
 /*换行符在注释开始标志不同时有不同的处理方式 */
<<EOF>> {
if(comment_type==1)
BEGIN(INITIAL);
else
{
yylval.error_msg="EOF in comment";
BEGIN(INITIAL);
return ERROR;
}
}
 /*对eof也是有不同的处理方式,在--开头时可以是终结符 */

"(*" {
num++;
}
 /*在注释里面再遇见(*的话,也要记录下来,所有的(*都被匹配注释才算结束 */
"*)" {
num--;
if(comment_type==0)
{if(!num)
{BEGIN(INITIAL);}
}
}
 /*遇见*)则匹配一个(*,都匹配掉则注释结束 */
. {}
 /*其他非特殊字符直接跳过 */
}

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

%%
