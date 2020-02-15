%{
#include <cstdio>
#include <map>
#include <string>
  
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
static Function *TheFunction;
static IRBuilder<> Builder(TheContext);


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

map<string,Value*> idMap;

BasicBlock *BBjoin = nullptr;
 
%}


%token IF WHILE RETURN IDENTIFIER IMMEDIATE ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE MINUS PLUS MULTIPLY DIVIDE NOT

%left PLUS MINUS
%left MULTIPLY DIVIDE
%right NOT

%union {
  char *id;
  int imm;
  Value * val;
  BasicBlock *bb;
}

%type <id> IDENTIFIER 
%type <imm> IMMEDIATE
%type <val> expr 


%start program

%%

program : LBRACE stmtlist RETURN expr SEMI RBRACE
{
  Builder.CreateRet($4);
  YYACCEPT;
}
;

stmtlist :    stmt
           |  stmtlist stmt

;

stmt:   IDENTIFIER ASSIGN expr SEMI              /* expression stmt */
{
// Look to see if we already allocated it
  Value* var = NULL;
  if (idMap.find($1)==idMap.end()) {
     // We haven’t so make a spot on the stack
    var = Builder.CreateAlloca(Builder.getInt32Ty(),   
                               nullptr,$1);
     // remember this location and associate it with $1
    idMap[$1] = var;
  } else {
    var = idMap[$1];
  }
  // store $3 into $1’s location in memory
  Builder.CreateStore($3,var);
}
      | IF LPAREN expr RPAREN
      {
	BasicBlock *then = BasicBlock::Create(TheContext,"if.then",TheFunction);
	BasicBlock *join = BasicBlock::Create(TheContext,"if.join",TheFunction);

	Value *icmp = Builder.CreateICmpNE($3,Builder.getInt32(0),"icmp.if");
	Builder.CreateCondBr(icmp,then,join);

	Builder.SetInsertPoint(then);
	$<bb>$ = join;
      }
      LBRACE stmtlist RBRACE   /*if stmt*/
      {
	Builder.CreateBr($<bb>5);
	Builder.SetInsertPoint($<bb>5);

      }
      | WHILE LPAREN expr RPAREN LBRACE stmtlist RBRACE /*while stmt*/
      | SEMI /* null stmt */
;

expr:   IDENTIFIER
{
  $$ = Builder.CreateLoad(idMap[$1],$1);
}
| IMMEDIATE
 {
   $$ = Builder.getInt32($1);
 }
| expr PLUS expr
 {
   $$ = Builder.CreateAdd($1,$3,"add");
 }
| expr MINUS expr
{
  $$ = Builder.CreateSub($1,$3,"sub");
}
| expr MULTIPLY expr
{
  $$ = Builder.CreateMul($1,$3,"mul");
}
| expr DIVIDE expr
{
  $$ = Builder.CreateSDiv($1,$3,"sdiv");
}
| MINUS expr
{
  $$ = Builder.CreateNeg($2,"neg");
}
| NOT expr
{
   Value *icmp = Builder.CreateICmpEQ($2,Builder.getInt32(0));
   $$ = Builder.CreateSelect(icmp,Builder.getInt32(1), 
                            Builder.getInt32(0));

}
| LPAREN expr RPAREN
{
  $$ = $2;
}
;



%%

int main() {

  // Make Module
  Module *M = new Module("Tutorial3", TheContext);
  
  // Create void function type with no arguments
  FunctionType *FunType = 
    FunctionType::get(Builder.getInt32Ty(),false);
  
  // Create a main function
  TheFunction = Function::Create(FunType,  
					GlobalValue::ExternalLinkage, "tutorial3",M);
  
  //Add a basic block to main to hold instructions
  BasicBlock *BB = BasicBlock::Create(TheContext, "entry",
				      TheFunction);

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
