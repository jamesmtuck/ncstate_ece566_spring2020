%{
#include <cstdio>
#include <list>
#include <iostream>
#include <string>
#include <memory>
#include <stdexcept>

using namespace std;
  
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

int regCnt=8;

 struct reg_or_imm {
   int kind; // 0 : reg, 1: imm
   int val;  // store the register number or the immediate
 };
 
%}


%union {
  int reg;
  int imm;
}

%token REG ASSIGN MINUS PLUS IMMEDIATE LPAREN RPAREN LBRACKET RBRACKET
%token SEMI ERROR

%left PLUS MINUS

%type <reg> REG expr
%type <imm> IMMEDIATE

%%

program:   REG ASSIGN expr SEMI
{
  //printf("program: REG (%d) ASSIGN expr (%d) SEMI\n", $1, $3);

  string add = format("ADD R%d, R%d, 0", $1, $3);

  printf("%s\n",add.c_str());  

  return 0;
}
;

expr: IMMEDIATE
{
  //printf("expr: IMMEDIATE (%d) \n", $1);
  int reg = regCnt++;
  string i1 = format("AND R%d, R%d, 0",reg,reg);
  string i2 = format("ADD R%d, R%d, %d",reg, reg, $1);

  printf("%s\n",i1.c_str());
  printf("%s\n",i2.c_str());
  $$ = reg;
}
| REG
{
  //printf("expr: REG (%d)\n",$1);
  $$ = $1;
}
| expr PLUS expr
{
  int reg = regCnt++;
  string add = format("ADD R%d, R%d, R%d",reg, $1, $3);

  printf("%s\n",add.c_str());
  $$ = reg;
}
| expr MINUS expr
{
  //printf("expr: expr MINUS expr\n");
  int reg = regCnt++;
  string sub = format("SUB R%d, R%d, R%d",reg, $1, $3);

  printf("%s\n",sub.c_str());
  $$ = reg;
}
| MINUS expr
{
  //printf("expr: MINUS expr\n");
  int reg = regCnt++;
  string i1 = format("NOT R%d, R%d",reg,$2);
  string i2 = format("ADD R%d, R%d, 1",reg, reg);

  printf("%s\n",i1.c_str());
  printf("%s\n",i2.c_str());
  $$ = reg;

}
| LPAREN expr RPAREN
{
  //printf("expr: LPAREN expr RPAREN \n");
  $$ = $2;
}
| LBRACKET expr RBRACKET
{
  int reg = regCnt++;
  string load = format("LDR R%d, R%d, 0",reg, $2);

  printf("%s\n",load.c_str());
  $$ = reg;
  
}
;

%%

void yyerror(const char* msg)
{
  printf("%s",msg);
}
