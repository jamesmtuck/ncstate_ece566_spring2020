%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

#include "list.h"
#include "symbol.h"

int num_errors;

extern int yylex();   /* lexical analyzer generated from lex.l */

int yyerror();
int parser_error(const char*);

void cmm_abort();
char *get_filename();
int get_lineno();

int loops_found=0;

extern LLVMModuleRef Module;
extern LLVMContextRef Context;
 LLVMBuilderRef Builder;

LLVMValueRef Function=NULL;
LLVMValueRef BuildFunction(LLVMTypeRef RetType, const char *name, 
			   paramlist_t *params);

%}

/* Data structure for parse tree nodes */

%union {
  int inum;
  char * id;
  LLVMTypeRef  type;
  LLVMValueRef value;
  LLVMBasicBlockRef bb;
  paramlist_t *params;
}

/* these tokens are simply their corresponding int values, more terminals*/

%token SEMICOLON COMMA MYEOF
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET

%token ASSIGN PLUS MINUS STAR DIV MOD 
%token LT GT LTE GTE EQ NEQ
%token BITWISE_OR BITWISE_XOR LSHIFT RSHIFT BITWISE_INVERT
%token DOT AMPERSAND 

%token FOR WHILE IF ELSE DO RETURN SWITCH
%token BREAK CONTINUE CASE COLON
%token INT VOID BOOL
%token I2P P2I SEXT ZEXT

/* NUMBER and ID have values associated with them returned from lex*/

%token <inum> CONSTANT_INTEGER /*data type of NUMBER is num union*/
%token <id>  ID

%left EQ NEQ LT GT LTE GTE
%left BITWISE_OR
%left BITWISE_XOR
%left AMPERSAND
%left LSHIFT RSHIFT
%left PLUS MINUS
%left MOD DIV STAR 
%nonassoc ELSE

%type <type> type_specifier

%type <value> opt_initializer
%type <value> expression bool_expression
%type <value> lvalue_location primary_expression unary_expression
%type <value> constant constant_expression unary_constant_expression

%type <params> param_list_opt param_list

%%

translation_unit:	  external_declaration
			| translation_unit external_declaration
                        | translation_unit MYEOF
{
  YYACCEPT;
}
;

external_declaration:	  function_definition
{
  /* finish compiling function */
  if(num_errors>100)
    {
      cmm_abort();
    }
  else if(num_errors==0)
    {
      
    }
}
                        | global_declaration 
;

function_definition:	  type_specifier ID LPAREN param_list_opt RPAREN
// NO MODIFICATION NEEDED
{
  symbol_push_scope();
  BuildFunction($1,$2,$4);  
}
compound_stmt 
{
  symbol_pop_scope();
}

// NO MODIFICATION NEEDED
| type_specifier STAR ID LPAREN param_list_opt RPAREN
{
  symbol_push_scope();
  BuildFunction(LLVMPointerType($1,0),$3,$5);
}
compound_stmt
{
  symbol_pop_scope();
}
;

global_declaration:    type_specifier STAR ID opt_initializer SEMICOLON
{
  // Check to make sure global isn't already allocated
  //LLVMAddGlobal(Module,?,?);
}
| type_specifier ID opt_initializer SEMICOLON
{
  // Check to make sure global isn't already allocated
  //LLVMAddGlobal(Module,$1,$2);
}
;

// YOU MUST FIXME: hacked to prevent segfault on initial testing
opt_initializer:   ASSIGN constant_expression { $$ = NULL; } | { $$ = NULL; } ;

// NO MODIFICATION NEEDED
type_specifier:		  INT
{
  $$ = LLVMInt64Type();
}
                     |    VOID
{
  $$ = LLVMVoidType();
}
;


param_list_opt:           
{
  $$ = NULL;
}
| param_list
{
  $$ = $1;
}
;

// USED FOR FUNCTION DEFINITION; NO MODIFICATION NEEDED
param_list:	
param_list COMMA type_specifier ID
{
  $$ = push_param($1,$4,$3);
}
| param_list COMMA type_specifier STAR ID
{
   $$ = push_param($1,$5,LLVMPointerType($3,0));
}
| type_specifier ID
{
  $$ = push_param(NULL, $2, $1);
}
| type_specifier STAR ID
{
  $$ = push_param(NULL, $3, LLVMPointerType($1,0));
}
;


statement:		  expr_stmt            
			| compound_stmt        
			| selection_stmt       
			| iteration_stmt       
			| return_stmt            
                        | break_stmt
                        | continue_stmt
                        | case_stmt
;

expr_stmt:	           SEMICOLON            
			|  assign_expression SEMICOLON       
;

local_declaration:    type_specifier STAR ID opt_initializer SEMICOLON
{

  symbol_insert($3,  /* map name to alloca */
		    LLVMBuildAlloca(Builder,LLVMPointerType($1,0),$3)); /* build alloca */

}
| type_specifier ID opt_initializer SEMICOLON
{
  symbol_insert($2,  /* map name to alloca */
		LLVMBuildAlloca(Builder,$1,$2)); /* build alloca */

}
;

local_declaration_list:	   local_declaration
                         | local_declaration_list local_declaration  
;

local_declaration_list_opt:	
			| local_declaration_list
;

compound_stmt:		  LBRACE {
  // PUSH SCOPE TO RECORD VARIABLES WITHIN COMPOUND STATEMENT
  symbol_push_scope();
}
local_declaration_list_opt
statement_list_opt 
{
  // POP SCOPE TO REMOVE VARIABLES NO LONGER ACCESSIBLE
  symbol_pop_scope();
}
RBRACE
;


statement_list_opt:	
			| statement_list
;

statement_list:		statement
		      | statement_list statement
;

break_stmt:               BREAK SEMICOLON
;

case_stmt:                CASE constant_expression COLON
;

continue_stmt:            CONTINUE SEMICOLON
;

selection_stmt:		  
  IF LPAREN bool_expression RPAREN statement ELSE statement
| SWITCH LPAREN expression RPAREN statement 
;


iteration_stmt:
  WHILE LPAREN bool_expression RPAREN statement
| FOR LPAREN expr_opt SEMICOLON bool_expression SEMICOLON expr_opt RPAREN statement 
| DO statement WHILE LPAREN bool_expression RPAREN SEMICOLON
;

expr_opt:  	
	| assign_expression
;

return_stmt:		  RETURN SEMICOLON
			| RETURN expression SEMICOLON
;

bool_expression: expression 
;

assign_expression:
  lvalue_location ASSIGN expression
| expression
;

expression:
  unary_expression
| expression BITWISE_OR expression
| expression BITWISE_XOR expression
| expression AMPERSAND expression
| expression EQ expression
| expression NEQ expression
| expression LT expression
| expression GT expression
| expression LTE expression
| expression GTE expression
| expression LSHIFT expression
| expression RSHIFT expression
| expression PLUS expression
| expression MINUS expression
| expression STAR expression
| expression DIV expression
| expression MOD expression
| BOOL LPAREN expression RPAREN
| I2P LPAREN expression RPAREN
| P2I LPAREN expression RPAREN
| ZEXT LPAREN expression RPAREN
| SEXT LPAREN expression RPAREN
| ID LPAREN argument_list_opt RPAREN
| LPAREN expression RPAREN
;


argument_list_opt: | argument_list
;

argument_list:
  expression
| argument_list COMMA expression
;


unary_expression:         primary_expression
| AMPERSAND primary_expression
| STAR primary_expression
| MINUS unary_expression
| PLUS unary_expression
| BITWISE_INVERT unary_expression
;

primary_expression:
  lvalue_location
| constant
;

lvalue_location:
  ID
| lvalue_location LBRACKET expression RBRACKET
| STAR LPAREN expression RPAREN
;

constant_expression:
  unary_constant_expression
| constant_expression BITWISE_OR constant_expression
| constant_expression BITWISE_XOR constant_expression
| constant_expression AMPERSAND constant_expression
| constant_expression LSHIFT constant_expression
| constant_expression RSHIFT constant_expression
| constant_expression PLUS constant_expression
| constant_expression MINUS constant_expression
| constant_expression STAR constant_expression
| constant_expression DIV constant_expression
| constant_expression MOD constant_expression
| I2P LPAREN constant_expression RPAREN
| LPAREN constant_expression RPAREN
;

unary_constant_expression:
  constant
| MINUS unary_constant_expression
| PLUS unary_constant_expression
| BITWISE_INVERT unary_constant_expression
;


constant:	          CONSTANT_INTEGER
{
  $$ = LLVMConstInt(LLVMInt64TypeInContext(Context),$1,(LLVMBool)1);
}
;




%%

LLVMValueRef BuildFunction(LLVMTypeRef RetType, const char *name, 
			   paramlist_t *params)
{
  int i;
  int size = paramlist_size(params);
  LLVMTypeRef *ParamArray = malloc(sizeof(LLVMTypeRef)*size);
  LLVMTypeRef FunType;
  LLVMBasicBlockRef BasicBlock;

  paramlist_t *tmp = params;
  /* Build type for function */
  for(i=size-1; i>=0; i--) 
    {
      ParamArray[i] = tmp->type;
      tmp = next_param(tmp);
    }
  
  FunType = LLVMFunctionType(RetType,ParamArray,size,0);

  Function = LLVMAddFunction(Module,name,FunType);
  
  /* Add a new entry basic block to the function */
  BasicBlock = LLVMAppendBasicBlock(Function,"entry");

  /* Create an instruction builder class */
  Builder = LLVMCreateBuilder();

  /* Insert new instruction at the end of entry block */
  LLVMPositionBuilderAtEnd(Builder,BasicBlock);

  tmp = params;
  for(i=size-1; i>=0; i--)
    {
      LLVMValueRef alloca = LLVMBuildAlloca(Builder,tmp->type,tmp->name);
      LLVMBuildStore(Builder,LLVMGetParam(Function,i),alloca);
      symbol_insert(tmp->name,alloca);
      tmp=next_param(tmp);
    }

  return Function;
}


extern int verbose;
extern int line_num;
extern char *infile[];
static int   infile_cnt=0;
extern FILE * yyin;
extern int use_stdin;

int parser_error(const char *msg)
{
  printf("%s (%d): Error -- %s\n",infile[infile_cnt-1],line_num,msg);
  return 1;
}

int internal_error(const char *msg)
{
  printf("%s (%d): Internal Error -- %s\n",infile[infile_cnt-1],line_num,msg);
  return 1;
}

int yywrap() {

  if (use_stdin)
    {
      yyin = stdin;
      return 0;
    }

  static FILE * currentFile = NULL;

  if ( (currentFile != 0) ) {
    fclose(yyin);
  }
  
  if(infile[infile_cnt]==NULL)
    return 1;

  currentFile = fopen(infile[infile_cnt],"r");
  if(currentFile!=NULL)
    yyin = currentFile;
  else
    printf("Could not open file: %s",infile[infile_cnt]);

  infile_cnt++;
  
  return (currentFile)?0:1;
}

int yyerror()
{
  parser_error("Un-resolved syntax error.");
  return 1;
}

char * get_filename()
{
  return infile[infile_cnt-1];
}

int get_lineno()
{
  return line_num;
}


void cmm_abort()
{
  parser_error("Too many errors to continue.");
  exit(1);
}
