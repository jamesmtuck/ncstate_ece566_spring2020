%{
#include <stdio.h>

int regCnt=10;

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

void yyerror(const char*);
int yylex();

static LLVMBuilderRef  Builder;

%}

%token IF WHILE RETURN IDENTIFIER IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE MINUS PLUS MULTIPLY DIVIDE NOT

%left PLUS MINUS
%left MULTIPLY DIVIDE
%right NOT

%union {
  char *id;
  int imm;
}

//%type <id> REG expr
//%type <imm> IMMEDIATE
//

%%

program : LBRACE stmtlist RETURN expr SEMI RBRACE
;

stmtlist :    stmt
           |  stmtlist stmt

;

stmt:   IDENTIFIER ASSIGN expr SEMI              /* expression stmt */
      | IF LPAREN expr RPAREN LBRACE stmtlist RBRACE   /*if stmt*/     
      | WHILE LPAREN expr RPAREN LBRACE stmtlist RBRACE /*while stmt*/
      | SEMI /* null stmt */
;

expr:   IDENTIFIER
      | IMMEDIATE
      | expr PLUS expr
      | expr MINUS expr
      | expr MULTIPLY expr
      | expr DIVIDE expr
      | MINUS expr
      | NOT expr
      | LPAREN expr RPAREN
;


%%

int main() {

// Make a Module
  LLVMModuleRef Module = LLVMModuleCreateWithName("main");
  
  // Make a void function type with no arguments
  LLVMTypeRef IntFnTy = LLVMFunctionType(LLVMInt32Type(),NULL,0,0);
  
  // Make a void function named main (the start of the program!)
  LLVMValueRef Fn = LLVMAddFunction(Module,"main",IntFnTy);

  // Add a basic block to main to hold new instructions
  LLVMBasicBlockRef BB = LLVMAppendBasicBlock(Fn,"entry");
  
  // Create a Builder object that will construct IR for us
  Builder = LLVMCreateBuilder();
  LLVMPositionBuilderAtEnd(Builder,BB);

  // Now we’re ready to make IR, call yyparse()

  // yyparse() triggers parsing of the input
  if (yyparse()==0) {
     LLVMBuildRet(Builder,LLVMConstInt(LLVMInt32Type(),0,0));
     LLVMWriteBitcodeToFile(Module,"main.bc");
    // all is good
  } else {
    printf("There was a problem! Read error messages above.\n");
  }
  return 0;
}

