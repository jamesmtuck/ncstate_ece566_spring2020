%{
#include <cstdio>
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
using namespace std;
 
static LLVMContext TheContext;
static IRBuilder<> Builder(TheContext);

int regCnt = 8;

int yylex();
int yyerror(const char *);


// helper code 
template<typename ... Args>
std::string format_helper( const std::string& format, Args ... args )
{
    size_t size = snprintf( nullptr, 0, format.c_str(), args ... ) + 1; // Extra space for '\0'
    std::unique_ptr<char[]> buf( new char[ size ] ); 
    snprintf( buf.get(), size, format.c_str(), args ... );
    return std::string( buf.get(), buf.get() + size - 1 ); // We don't want the '\0' inside
}

 Value * reg[8] = { nullptr };

 struct somestuff {
   int x;
   Value *y;
   double z;
 };
 
%}


%token REG IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACKET RBRACKET MINUS PLUS

%left PLUS MINUS

%union {
  int reg;
  int imm;
  Value * val;
}

%type <reg> REG 
%type <imm> IMMEDIATE
%type <val> expr program

%start program

%%

program: REG ASSIGN expr SEMI 
{
  $$ = $3;
  reg[$1] = $3;
} 
| program REG ASSIGN expr SEMI
{
  $$ = $4;
  reg[$2] = $4;
} 

| program SEMI
{
  Builder.CreateRet($1);
  return 0;
}
;
expr: 
 IMMEDIATE                 
 {
   $$ = Builder.getInt32($1);
   
   //ConstantInt *ci = dyn_cast<ConstantInt>($$);
   //if (ci != NULL) {
   //  printf("%ld\n", ci->getZExtValue());
   //}
 }
| REG
 {
   $$ = reg[$1];
   // worried about: is reg[$1] a good value or is it junk?
 }
| expr PLUS expr  
 {
   $$ = Builder.CreateAdd($1,$3);
 }

| expr MINUS expr 
 {
   $$ = Builder.CreateSub($1,$3);

 }

| LPAREN expr RPAREN 
 {
   $$ = $2;
 }

| MINUS expr 
 {
   $$ = Builder.CreateNeg($2);
 }

| LBRACKET expr RBRACKET 
 {
   Value *inttoptr = Builder.CreateIntToPtr($2,PointerType::get(Builder.getInt32Ty(),0));
   $$ = Builder.CreateLoad(inttoptr);
 }

;

%%

int main() {

  // Make Module
  Module *M = new Module("Tutorial2", TheContext);
  
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

  for(int i=0; i<8; i++)
    {
      reg[i] = Builder.getInt32(0);
    }
  
  // Now we’re ready to make IR, call yyparse()
  
  // yyparse() triggers parsing of the input
  if (yyparse()==0) {
    // all is good

    // Build the return instruction for the function
    //Builder.CreateRet(Builder.getInt32(0));

    // Dump LLVM IR to the screen for debugging
    M->print(errs(),nullptr,false,true);
    
    
    //Write module to file
    std::error_code EC;
    raw_fd_ostream OS("main.bc",EC,sys::fs::F_None);  
    WriteBitcodeToFile(*M,OS);
    
  } else {
    printf("There was a problem! Read error messages above.\n");
  }

  return 0;
}
