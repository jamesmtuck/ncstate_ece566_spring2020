%{
#include <stdio.h>
#include <list>
#include <iostream>
  
int yylex();
void yyerror(const char*);

 extern "C" {
   int yyparse();
 }
%}


%token REG ASSIGN MINUS PLUS IMMEDIATE LPAREN RPAREN LBRACKET RBRACKET
%token SEMI

%left PLUS MINUS 

%%

program:   REG ASSIGN expr SEMI
;

expr: IMMEDIATE 
| REG
| expr PLUS expr
| expr MINUS expr
| MINUS expr 
| LPAREN expr RPAREN
| LBRACKET expr RBRACKET
;

%%

void yyerror(const char* msg)
{
}
