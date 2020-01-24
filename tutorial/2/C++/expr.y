%{
#include <stdio.h>
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/IRBuilder.h"

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;

static LLVMContext TheContext;
static IRBuilder<> Builder(TheContext);

int regCnt = 8;

int yylex();
int yyerror(const char *);

%}

%token REG IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACKET RBRACKET MINUS PLUS

%left PLUS MINUS

%union {
  int reg;
  int imm;
}

%type <reg> REG expr
%type <imm> IMMEDIATE

%start program

%%

program: REG ASSIGN expr SEMI 
{

} 
| program REG ASSIGN expr SEMI
{

} 

| program SEMI
{
  //Builder.CreateRet(Builder.getInt32(0));
  return 0;
}
;
expr: 
 IMMEDIATE                 
 {
   //$$ = Builder.getInt32($1);
   
   //ConstantInt *ci = dyn_cast<ConstantInt>($$);
   //if (ci != NULL) {
   //  printf("%ld\n", ci->getZExtValue());
   //}

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
   $$ = $2;
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

  // Make Module
  Module *M = new Module("Tutorial1", TheContext);
  
  // Create void function type with no arguments
  FunctionType *FunType = 
    FunctionType::get(Builder.getInt32Ty(),false);
  
  // Create a main function
  Function *Function = Function::Create(FunType,  
					GlobalValue::ExternalLinkage, "main",M);
  
  //Add a basic block to main to hold instructions
  BasicBlock *BB = BasicBlock::Create(TheContext, "entry",
				      Function);

  // Ask builder to place new instructions at end of the
  // basic block
  Builder.SetInsertPoint(BB);
  
  // Now we’re ready to make IR, call yyparse()
  
  // yyparse() triggers parsing of the input
  if (yyparse()==0) {
    // all is good

    // Build the return instruction for the function
    Builder.CreateRet(Builder.getInt32(0));
    
    M->dump(); // dump module to screen for viewing/debugging

    //Write module to file
    std::error_code EC;
    raw_fd_ostream OS("main.bc",EC,sys::fs::F_None);  
    WriteBitcodeToFile(M,OS);

  } else {
    printf("There was a problem! Read error messages above.\n");
  }

  return 0;
}
