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
 
%}


%token IF WHILE RETURN IDENTIFIER IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE MINUS PLUS MULTIPLY DIVIDE NOT

%left PLUS MINUS
%left MULTIPLY DIVIDE
%right NOT

%union {
  char *id;
  int imm;
  Value * val;
}

//%type <id> IDENTIFIER 
//%type <imm> IMMEDIATE
//%type <val> expr stmt function


%start program

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

  // Make Module
  Module *M = new Module("Tutorial3", TheContext);
  
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
