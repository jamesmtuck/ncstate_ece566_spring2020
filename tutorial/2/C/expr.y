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

%token REG IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACKET RBRACKET MINUS PLUS

%left PLUS MINUS

%union {
  int reg;
  int imm;
}

//%type <reg> REG expr
//%type <imm> IMMEDIATE

%%

program: REG ASSIGN expr SEMI 
{

  
}
| program REG ASSIGN expr SEMI 
{ 

}
| program SEMI          
   { 
     YYACCEPT;
   }
;

expr: 

 IMMEDIATE                 
 {


 }
| REG
{


}  
| expr PLUS expr  
{


}  
| expr MINUS expr 
{


}  

| LPAREN expr RPAREN 
{


}  

| MINUS expr 
{


}  

| LBRACKET expr RBRACKET 
{



}  

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

