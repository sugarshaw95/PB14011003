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

%}

%option noyywrap



%x comment
%x str   /*define start conditions for string and comments */



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
signs "+"|"-"|"-"|"*"|"="|"<"|"."|"~"|","|";"|":"|"("|")"|"@"|"{"|"}" 
int  [0-9]+
typid [A-Z][a-zA-Z_]*
objid [a-z][a-zA-Z_]*
digit       [0-9]

%%

char string_buf[MAX_STR_CONST];
char *string_buf_ptr;

 /*normal case(not string or comments) */
INITIAL{

{class} {return CLASS}
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
{assgin} {return ASSIGN;}
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

int n=atoi(yytext);
inttable.add_int(n);
return INT_CONST;
}

{typid} {
idtable.add_string(yytext);
return 	TYPEID;
}

{objid} {
idtable.add_string(yytext);
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
 /*invalid chars -  */

\" {string_buf_pyr= string_buf;BEGIN(str);}

--  {BEGIN(commment);}

"(*"   {BEGIN(comment);}

}



str{
\"  {
BEGIN(INITIAL);
*string_buf_ptr='\0';}
\n {
yylval.error_msg="Unterminated string constant";
return ERROR;
}
\0 {
yylval.error_msg="String contains null character";
return ERROR;
}

<<EOF>> {
yylval.error_msg="EOF in string constant";
return ERROR;
}



\\n *stromg_buf_ptr++='\n';
\\b *stromg_buf_ptr++='\b';
\\t *stromg_buf_ptr++='\t';
\\f *stromg_buf_ptr++='\f';

\\ {

} /* delete "\" */

}




comment{
\n|<<EOF>> {BEGIN(INITIAL);}

"*)" {BEGIN(INITIAL);}

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
