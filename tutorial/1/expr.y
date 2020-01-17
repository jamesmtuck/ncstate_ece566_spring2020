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
%token SEMI ERROR

%left PLUS MINUS 

%%

program:   REG ASSIGN expr SEMI
{
  printf("program: REG ASSIGN expr SEMI\n");
  return 0;
}
;

expr: IMMEDIATE { printf("expr: IMMEDIATE\n"); }
| REG
{
  printf("expr: REG\n"); 
}
| expr PLUS expr
{ printf("expr: expr PLUS expr\n");  }
| expr MINUS expr
{ printf("expr: expr MINUS expr\n");  }
| MINUS expr
{ printf("expr: MINUS expr\n");  }
| LPAREN expr RPAREN
{ printf("expr: LPAREN expr RPAREN \n");  }
| LBRACKET expr RBRACKET
{ printf("expr: LBRACKET expr RBRACKET \n");  }
;

%%

void yyerror(const char* msg)
{
  printf("%s",msg);
}
