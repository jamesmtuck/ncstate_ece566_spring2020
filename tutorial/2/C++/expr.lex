%{
#include <stdio.h>
#include <stdlib.h>

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/IRBuilder.h"

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;

#include "expr.y.hpp"
int yyerror(char *s);

int yylex();
int yyerror(const char *);


%}

%option noyywrap noinput nounput

%% // begin tokens

[ \n\t]                   // just ignore it

[rR][0-7]                 {  
                             yylval.reg = atoi(yytext+1); return REG; }

[0-9]+                    {  
                             yylval.imm = atoi(yytext); return IMMEDIATE; }

"="                       { return ASSIGN; }
";"                       { return SEMI; }

"("                       { return LPAREN; }
")"                       { return RPAREN; }

"["                       { return LBRACKET; }
"]"                       { return RBRACKET; }

"+"                       { return PLUS; }
"-"                       { return MINUS; }

"//"[^\n]*                

.                         { yyerror("Illegal character!"); yyterminate(); }

%% // end tokens


int yyerror(const char *s)
{
  fprintf(stderr,"%d: %s %s\n", yylineno, s, yytext);
  return 0;
}
