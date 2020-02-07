%{
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <list>
#include <map>
  
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;
using namespace std;

extern FILE *yyin;
int yylex(void);
int yyerror(const char *);

// From main.cpp
extern char *fileNameOut;
extern Module *M;
extern LLVMContext TheContext;
extern Function *Func;
extern IRBuilder<> Builder;

// Used to lookup Value associated with ID
map<string,Value*> idLookup;
 
%}

%union {
  int num;
  char *id;
}

%token IDENT NUM MINUS PLUS MULTIPLY DIVIDE LPAREN RPAREN SETQ SETF AREF MIN MAX ERROR MAKEARRAY

%type <num> NUM 
%type <id> IDENT

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
  Builder.CreateRet(Builder.getInt32(0));
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
| LPAREN SETQ IDENT token_or_expr RPAREN
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
| LPAREN AREF IDENT token_or_expr RPAREN
{
  // IMPLEMENT

}
| LPAREN MAKEARRAY IDENT NUM token_or_expr RPAREN
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
  // HINT: $$ = new std::list<Value*>;
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

token:   IDENT
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
  string s = "arg_array";
  idLookup[s] = (Value*)(Func->arg_begin()+1);

  string s2 = "arg_size";
  Argument *a = Func->arg_begin();
  Value * v = Builder.CreateAlloca(a->getType());
  Builder.CreateStore(a,v);
  idLookup[s2] = (Value*)v;
  
  /* IMPLEMENT: add something else here if needed */
}

extern int line;

int yyerror(const char *msg)
{
  printf("%s at line %d.\n",msg,line);
  return 0;
}
