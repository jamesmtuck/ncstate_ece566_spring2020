%{
#include <stdio.h>

int regCnt=10;

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

#include "uthash.h"

void yyerror(const char*);
int yylex();

static LLVMBuilderRef  Builder;

struct TmpMap{
  char *key;                /* key */
  void *val;                /* data */
  UT_hash_handle hh;        /* makes this structure hashable */
};
 

struct TmpMap *map = NULL;    /* important! initialize to NULL */

void map_insert(char *key, void* val) { 
  struct TmpMap *s; 
  s = malloc(sizeof(struct TmpMap)); 
  s->key = strdup(key); 
  s->val = val; 
  HASH_ADD_KEYPTR( hh, map, s->key, strlen(s->key), s ); 
}

void * map_find(char *tmp) {
  struct TmpMap *s;
  HASH_FIND_STR( map, tmp, s );  /* s: output pointer */
  if (s) 
    return s->val;
  else 
    return NULL; // returns NULL if not found
}
 
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
  LLVMValueRef Fn = LLVMAddFunction(Module,"tutorial3",IntFnTy);

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

