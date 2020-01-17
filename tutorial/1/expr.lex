%{
#include <stdio.h>
#include <math.h>
%}

%option noyywrap

%% // begin tokens

"+"  { printf("PLUS"); }

.    { printf("Illegal character!"); }

%% // end tokens
