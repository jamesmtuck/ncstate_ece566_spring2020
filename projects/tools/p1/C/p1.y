%{

#include <stdio.h>
#include <string.h>
#include <errno.h>
  
#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

#include "uthash.h"


extern FILE *yyin;
int yylex(void);
int yyerror(const char *);

extern char *fileNameOut;

extern LLVMModuleRef Module;
extern LLVMContextRef Context;

LLVMValueRef Function;
LLVMBasicBlockRef BasicBlock;
LLVMBuilderRef Builder;

struct TmpMap{
  char *key;                /* key */
  void *val;                /* data */
  UT_hash_handle hh;        /* makes this structure hashable */
};
 

struct TmpMap *map = NULL;    /* important! initialize to NULL */

void map_insert(char *key, void* val) { 
  struct TmpMap *s; 
  s = malloc(sizeof(struct TmpMap)); 
  s->key = strdup(key); 
  s->val = val; 
  HASH_ADD_KEYPTR( hh, map, s->key, strlen(s->key), s ); 
}

void * map_find(char *tmp) {
  struct TmpMap *s;
  HASH_FIND_STR( map, tmp, s );  /* s: output pointer */
  if (s) 
    return s->val;
  else 
    return NULL; // returns NULL if not found
}
 
%}

%union {
  int num;
  char *id;
}

%token ID NUM MINUS PLUS MULTIPLY DIVIDE LPAREN RPAREN SETQ SETF AREF MIN MAX ERROR MAKEARRAY

%type <num> NUM 
%type <id> ID

%start program

%%


/*
   IMPLMENT ALL THE RULES BELOW HERE!
 */

program : exprlist 
{ 
  /* 
    IMPLEMENT: return value
    Hint: the following code is not sufficient
  */
  
  LLVMBuildRet(Builder,LLVMConstInt(LLVMInt32Type(),0,0));

  return 0;
}
;

exprlist:  exprlist expr | expr // MAYBE ADD ACTION HERE?
;         

expr: LPAREN MINUS token_or_expr_list RPAREN
{ 
  // IMPLEMENT
}
| LPAREN PLUS token_or_expr_list RPAREN
{
  // IMPLEMENT
}
| LPAREN MULTIPLY token_or_expr_list RPAREN
{
  // IMPLEMENT
}
| LPAREN DIVIDE token_or_expr_list RPAREN
{
  // IMPLEMENT
}
| LPAREN SETQ ID token_or_expr RPAREN
{
  // IMPLEMENT
}
| LPAREN MIN token_or_expr_list RPAREN
{
  // HINT: select instruction

}
| LPAREN MAX token_or_expr_list RPAREN
{
  // HINT: select instruction
  
}
| LPAREN SETF token_or_expr token_or_expr RPAREN
{
  // ECE 566 only
  // IMPLEMENT
}
| LPAREN AREF ID token_or_expr RPAREN
{
  // IMPLEMENT

}
| LPAREN MAKEARRAY ID NUM token_or_expr RPAREN
{
  // ECE 566 only
  // IMPLEMENT

}
;

token_or_expr_list:   token_or_expr_list token_or_expr
{
  // IMPLEMENT
}
| token_or_expr
{
  // IMPLEMENT
}
;

token_or_expr :  token
{
  // IMPLEMENT
}
| expr
{
  // IMPLEMENT
}
; 

token:   ID
{
  /*if (idLookup.find($1) != idLookup.end())
    $$ = Builder.CreateLoad(idLookup[$1]);
  else
    {
      YYABORT;      
      }*/
}
| NUM
{
  // IMPLEMENT
}
;

%%

void initialize()
{
  LLVMTypeRef Int32 = LLVMInt32TypeInContext(Context);

  LLVMValueRef val = LLVMBuildAlloca(Builder,Int32,"arg_size");
  LLVMBuildStore(Builder,LLVMGetParam(Function,0),val);
  map_insert("arg_size",val);
  
  map_insert("arg_array",LLVMGetParam(Function,1));

  /* IMPLEMENT: add something else here if needed */
}

extern int line;

int yyerror(const char *msg)
{
  printf("%s at line %d.\n",msg,line);
  return 0;
}
