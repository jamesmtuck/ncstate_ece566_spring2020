%{
#include <stdio.h>
#include <iostream>
#include <math.h>
#include "expr.y.hpp"
  
  //extern "C" {
  //  int yylex();
  //}

%}

%option noyywrap


%% // begin tokens


[ \n\t]  // ignore a space, a tab, a newline


[Rr][0-7]  { yylval.reg = atoi(yytext+1); return REG; }
[0-9]+     { yylval.imm = atoi(yytext); return IMMEDIATE; }
"="        { /*printf("ASSIGN ");*/ return ASSIGN; }
;          { /*printf("SEMI ");*/ return SEMI; }
"("        { /*printf("LPAREN ");*/ return LPAREN; }
")"        { /*printf("RPAREN ");*/ return RPAREN;  }
"["        { /*printf("LBRACKET ");*/ return LBRACKET; }
"]"        { /*printf("RBRACKET ");*/ return RBRACKET; }
"-"        { /*printf("MINUS ");*/ return MINUS; }
"+"        { /*printf("PLUS ");*/ return PLUS; }

"//".*\n  { }


.    { printf("Illegal character! "); return ERROR; }

%% // end tokens

//

// (the rest of the line is ignored)
