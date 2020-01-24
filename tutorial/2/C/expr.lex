%{
#include <stdio.h>
#include <stdlib.h>

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

#include "expr.y.h"
  
void yyerror(const char *s);
int yylex();
%}

%option noyywrap noinput nounput

%% // begin tokens

[ \n\t]                   // just ignore it

[rR][0-7]                 { yylval.reg = atoi(yytext+1); return REG; }
[0-9]+                    { yylval.imm = atoi(yytext); return IMMEDIATE; }

"="                       { return ASSIGN; }
";"                       { return SEMI; }
"("                       { return LPAREN; }       
")"                       { return RPAREN; }
"["                       { return LBRACKET; }
"]"                       { return RBRACKET; }

"+"                       { return PLUS;}
"-"                       { return MINUS; }

"//"[^\n]*                //{ printf("COMMENT "); }

.                         { yyerror("Illegal character!"); yyterminate(); }

%% // end tokens

void yyerror(const char *s)
{
  fprintf(stderr,"%d: %s %s\n", yylineno, s, yytext);
}
