/*
 *  cool.y
 *              Parser definition for the COOL language.
 *
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

/* Add your own C declarations here */


/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

extern int yylex();           /* the entry point to the lexer  */
extern int curr_lineno;
extern char *curr_filename;
Program ast_root;            /* the result of the parse  */
Classes parse_results;       /* for use in semantic analysis */
int omerrs = 0;              /* number of errors in lexing and parsing */

/*
   The parser will always call the yyerror function when it encounters a parse
   error. The given yyerror implementation (see below) justs prints out the
   location in the file where the error was found. You should not change the
   error message of yyerror, since it will be used for grading puproses.
*/
void yyerror(const char *s);

/*
   The VERBOSE_ERRORS flag can be used in order to provide more detailed error
   messages. You can use the flag like this:

     if (VERBOSE_ERRORS)
       fprintf(stderr, "semicolon missing from end of declaration of class\n");

   By default the flag is set to 0. If you want to set it to 1 and see your
   verbose error messages, invoke your parser with the -v flag.

   You should try to provide accurate and detailed error messages. A small part
   of your grade will be for good quality error messages.
*/
extern int VERBOSE_ERRORS;

%}

/* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

/* 
   Declare the terminals; a few have types for associated lexemes.
   The token ERROR is never used in the parser; thus, it is a parse
   error when the lexer returns it.

   The integer following token declaration is the numeric constant used
   to represent that token internally.  Typically, Bison generates these
   on its own, but we give explicit numbers to prevent version parity
   problems (bison 1.25 and earlier start at 258, later versions -- at
   257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/
 
   /* Complete the nonterminal list below, giving a type for the semantic
      value of each non terminal. (See section 3.6 in the bison 
      documentation for details). */

/* Declare types for the grammar's non-terminals. */
%type <program> program
%type <classes> class_list
%type <class_> class

/* You will want to change the following line. */
%type <features> dummy_feature_list
%type <feature> attr
%type <feature> method
%type <case_> branch
%type <cases> branch_list
%type <formal> formal
%type <formals> formal_list
%type <expression> expr
%type <expression> let_sub /*写let表达式用到的新非终结符*/
%type <expressions> expr_list_dispatch /*dispatch中的exprlist */
%type <expressions> expr_list_block /*block中的exprlist */
/* Precedence declarations go here. */
%nonassoc IN
%right ASSIGN
%left NOT
%nonassoc LE '=' '<'
%left '+' '-'
%left '*' '/'
%left ISVOID
%left '~'
%left '@'
%left '.'



%%
/* 
   Save the root of the abstract syntax tree in a global variable.
*/
program : class_list { ast_root = program($1); }
        ;

class_list
        : class ';'           /* single class */
                { $$ = single_Classes($1); }
        | class_list class ';' /* several classes */
                { $$ = append_Classes($1,single_Classes($2)); }
        ;

/* If no parent is specified, the class inherits from the Object class. */
class  : CLASS TYPEID '{' dummy_feature_list '}' 
                { $$ = class_($2,idtable.add_string("Object"),$4,
                              stringtable.add_string(curr_filename)); }

        | CLASS TYPEID INHERITS TYPEID '{' dummy_feature_list '}' 
                { $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); }
        | CLASS error INHERITS TYPEID '{' dummy_feature_list '}' 
                { /*printf("Class error,invalid typeid(1st)!\n ");*/ yyerrok;}
        | CLASS TYPEID error TYPEID '{' dummy_feature_list '}' 
                { /*printf("Class error,inherits misspelled!\n ");*/ yyerrok;}
        | CLASS TYPEID INHERITS error '{' dummy_feature_list '}' 
                { /*printf("Class error,invalid typeid(2nd)!\n");*/ yyerrok;yyclearin;}
        | error TYPEID INHERITS TYPEID '{' dummy_feature_list '}' 
                { /*printf("Class error,class misspelled !\n");*/ yyerrok;}
        | CLASS TYPEID INHERITS TYPEID '{' dummy_feature_list error
                { /*printf("} missing\n");*/ yyerrok;}
        | CLASS TYPEID INHERITS TYPEID error dummy_feature_list '}'
                { /*printf("{ missing\n");*/ yyerrok;}                  
        | CLASS error  '}'
                { /*printf("{ missing\n");*/ yyerrok;} /*other type*/                                                                              
        ;

/* Feature list may be empty, but no empty features in list. */
dummy_feature_list:        /* empty */
                { $$ = nil_Features(); }
        | dummy_feature_list attr 
                { $$ = append_Features($1,single_Features($2)); }
        | dummy_feature_list method 
                { $$ = append_Features($1,single_Features($2)); }
            

        ;
/*feature_list可能由attr或者method组成 */
attr : OBJECTID ':' TYPEID ';'
                { $$=attr($1,$3,no_expr()); }
        | OBJECTID ':' TYPEID ASSIGN expr ';'
                { $$=attr($1,$3,$5); } 
        | OBJECTID ':' TYPEID ASSIGN error ';'
                { /*printf("attr error,assign expr error!\n ");*/ yyerrok;}
        | OBJECTID error TYPEID ASSIGN expr ';'
                { /*printf("attr error, ':' missing!\n ");*/ yyerrok;}
        | OBJECTID error TYPEID ';'
                { /*printf("attr error, ':' missing!\n ");*/ yyerrok;}                 
        | OBJECTID ':' TYPEID error expr ';'
                { /*printf("attr error,assign missing!\n ");*/yyerrok;}                                               
        | error ':' TYPEID ASSIGN expr ';'
                { /*printf("attr error,invalid objectid!\n");*/ yyerrok;}
        | OBJECTID ':' error ASSIGN expr ';'
                { /*printf("attr error,invalid typeid!\n");*/ yyerrok;}
        | error ':' TYPEID ';'
                { /*printf("attr error,invalid objectid!\n");*/ yyerrok;} 
        | OBJECTID ':' error ';'
                { /*printf("attr error,invalid typeid!\n");*/ yyerrok;} 
        | OBJECTID error ';'
                { /*printf("feature error,other type\n");*/yyerrok;}

        ;



method : OBJECTID '(' formal_list ')' ':' TYPEID '{' expr '}' ';'
                { $$=method($1,$3,$6,$8); }
        | OBJECTID '(' formal_list ')' ':' error '{' expr '}' ';'
                { /*printf("method error,invalid typeid!\n");*/ yyerrok;} 
        | error  formal_list ')' ':' TYPEID '{' expr '}' ';'
                { /*printf("method error,invalid objectid!\n");*/yyerrok;}
        | OBJECTID '(' error ')' ':' TYPEID '{' expr '}' ';'
                { /*printf("method error,formal_list error!\n");*/ yyerrok;}    
        | OBJECTID '(' formal_list ')' ':' TYPEID '{' error '}' ';'
                { /*printf("method error,expr error!\n");*/ yyerrok;} 
        | OBJECTID '(' formal_list ')' ':' TYPEID error expr '}' ';'
                { /*printf("method error,{ missing !\n");*/ yyerrok; }
        | OBJECTID '(' formal_list ')' ':' TYPEID '{' expr error ';'
                { /*printf("method error,} missing !\n");*/ yyerrok; } 
        | OBJECTID '(' formal_list ')' error TYPEID '{' expr '}' ';'
                { /*printf("method error,: missing !\n");*/ yyerrok; }
                                               
        ;


branch : OBJECTID ':' TYPEID DARROW expr ';'
                { $$=branch($1,$3,$5); }
        ;
branch_list : branch
                { $$=single_Cases($1); }
        | branch_list branch
                { $$=append_Cases($1,single_Cases($2)); }
        ;
/*branch_list不能为空 */
formal : OBJECTID ':' TYPEID
                { $$=formal($1,$3); }
        ;
formal_list : formal_list ',' formal
                { $$=append_Formals($1,single_Formals($3)); }
        | 
                { $$=nil_Formals(); } /* empty */
        |   formal
                { $$=single_Formals($1); }
        ;
/*这里要注意一个的情况要单独写一个生成式 */
expr_list_dispatch :
                { $$=nil_Expressions(); }
        | expr 
                { $$=single_Expressions($1); }
        | expr_list_dispatch ',' expr
                { $$=append_Expressions($1,single_Expressions($3)); }
        ;
/*同理,一个单独处理 */
expr_list_block : expr ';'
                { $$=single_Expressions($1); }
        | expr_list_block expr ';'
                { $$=append_Expressions($1,single_Expressions($2)); }
        | error ';'
                { /*printf("expr in {...} error!\n");*/yyerrok;} //expr error in {...}

        ;

expr :  OBJECTID ASSIGN expr
                { $$=assign($1,$3); } //assign
        | expr '@' TYPEID '.' OBJECTID '(' expr_list_dispatch ')'
                { $$=static_dispatch($1,$3,$5,$7); }
        | expr '.' OBJECTID '(' expr_list_dispatch ')'
                { $$=dispatch($1,$3,$5); }
        | OBJECTID '(' expr_list_dispatch ')'
                { $$=dispatch(object(idtable.add_string("self")),$1,$3); } /* 3 kinds of dispatch */
        | IF expr THEN expr ELSE expr FI  // if else then
                { $$=cond($2,$4,$6); }
        | WHILE expr LOOP expr POOL //循环
                { $$=loop($2,$4); }
        | '{' expr_list_block '}' //block
                { $$=block($2); }
        | LET OBJECTID ':' TYPEID ASSIGN expr let_sub 
                { $$=let($2,$4,$6,$7); }
        | LET OBJECTID ':' TYPEID  let_sub
                { $$=let($2,$4,no_expr(),$5); } /*let,递归表示 let_sub */
     
        | LET error let_sub
                { /*printf("let error\n");*/yyerrok;}

    
        | CASE expr OF branch_list ESAC //case语句
                { $$=typcase($2,$4); }
        | NEW TYPEID  /*下面全都是简单expr */
                { $$=new_($2); }
        | ISVOID expr
                { $$=isvoid($2); }
        | expr '+' expr 
                { $$=plus($1,$3); }                                               
        | expr '-' expr
                { $$=sub($1,$3); }
        | expr '*' expr
                { $$=mul($1,$3); }
        | expr '/' expr
                { $$=divide($1,$3); }
        | expr '+' error 
                { yyerrok; }                                               
        | expr '-' error
                { yyerrok; }
        | expr '*' error
                { yyerrok; }
        | expr '/' error
                { yyerrok;}                                
        | '~' expr
                { $$=neg($2); } 
        | expr '<' expr
                { $$=lt($1,$3); } 
        | expr LE expr
                { $$=leq($1,$3); } 
        | expr '=' expr
                { $$=eq($1,$3); } 
        | NOT expr
                { $$=comp($2); }               
        | '(' expr ')'
                { $$=$2; }
        | '(' error ')'
                { /*printf("not a expr\n");*/yyerrok; }                
        | OBJECTID
                { $$=object($1); }
        | INT_CONST
                { $$=int_const($1); }
        | STR_CONST
                { $$=string_const($1); }
        | BOOL_CONST
                { $$=bool_const($1); }
                                                                                                                                                                         
        ;

let_sub : ',' OBJECTID ':' TYPEID ASSIGN expr  let_sub
                { $$=let($2,$4,$6,$7); }
        | ',' OBJECTID ':' TYPEID  let_sub
                { $$=let($2,$4,no_expr(),$5); } 
        |  IN expr
                { $$=$2; }
 

        ;
/*表示let用到的新非终结符 */

/* end of grammar */
%%

/* This function is called automatically when Bison detects a parse error. */
void yyerror(const char *s)
{
  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
    << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;

  if(omerrs>20) {
      if (VERBOSE_ERRORS)
         fprintf(stderr, "More than 20 errors\n");
      exit(1);
  }
}

