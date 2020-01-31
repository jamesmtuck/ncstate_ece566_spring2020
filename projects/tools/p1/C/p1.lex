%{ 
/* P1. Implements scanner.  Some changes are needed! */

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

int line=1;

#include "p1.y.h" 
%}

%option nodefault 
%option yylineno
%option nounput
%option noinput
 
%% 

\n           line++;
[\t ]        ;


[a-zA-Z_][_a-zA-Z0-9]*  { yylval.id = strdup(yytext); return ID; } 

[0-9]+          

"-"	{ return MINUS;       } 
"+"	{ return PLUS;        }  
"*"	{ return MULTIPLY;    } 
"/"	{ return DIVIDE;      } 

"("     { return LPAREN;      }
")"     { return RPAREN;      }

.       { return ERROR;       }

%%
