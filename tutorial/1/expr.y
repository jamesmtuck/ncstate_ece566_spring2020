%{
#include <cstdio>
#include <list>
#include <iostream>
#include <string>
#include <memory>
#include <stdexcept>

int yylex();
void yyerror(const char*);

extern "C" {
  int yyparse();
}

// helper code 
template<typename ... Args>
std::string format( const std::string& format, Args ... args )
{
    size_t size = snprintf( nullptr, 0, format.c_str(), args ... ) + 1; // Extra space for '\0'
    if( size <= 0 ){ throw std::runtime_error( "Error during formatting." ); }
    std::unique_ptr<char[]> buf( new char[ size ] ); 
    snprintf( buf.get(), size, format.c_str(), args ... );
    return std::string( buf.get(), buf.get() + size - 1 ); // We don't want the '\0' inside
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
