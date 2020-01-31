#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "llvm-c/Core.h"
#include "llvm-c/BitReader.h"
#include "llvm-c/BitWriter.h"

extern FILE *yyin;
char *fileNameOut;
char *funName;
LLVMModuleRef Module;
LLVMContextRef Context;
LLVMValueRef Function;
LLVMBasicBlockRef BasicBlock;
LLVMBuilderRef Builder;

extern void initialize();
int yyparse();

void setup()
{
  LLVMTypeRef Int32 = LLVMInt32TypeInContext(Context);
  LLVMTypeRef typeArray[2] =
    {
     Int32,
     LLVMPointerType(Int32,0)
    };

  LLVMBool var_arg=0;
  LLVMTypeRef FunType = LLVMFunctionType(Int32,typeArray,2,var_arg);

  Function = LLVMAddFunction(Module,funName,FunType);

    /* Add a new entry basic block to the function */
  BasicBlock = LLVMAppendBasicBlock(Function,"entry");

  /* Create an instruction builder class */
  Builder = LLVMCreateBuilder();

  /* Insert new instruction at the end of entry block */
  LLVMPositionBuilderAtEnd(Builder,BasicBlock);
}

int
main (int argc, char ** argv)
{
  /* ./p1 filein fileout */

  if (argc < 3) {
    fprintf(stderr,"Not enough positional arguments to %s.\n",argv[0]);
    fprintf(stderr,"usage: %s filein.p1 fileout.bc\n",argv[0]);
    return 1;
  }

  /* create an LLVMContext for use when generating code */
  Context = LLVMGetGlobalContext();

  /* create an LLVM Module to hold the function */
  Module = LLVMModuleCreateWithNameInContext("main",Context);

  /* initialize parser related data if you need to */
  funName = strdup(argv[2]);
  char* pos = strchr(funName,'.');
  if (pos)
    *pos='\0';

  /* get module and function ready */
  setup();

  /* initialize data in parser */
  initialize();
  
  /* this is the name of the file to generate, you can also use
     this string to figure out the name of the generated function */
  fileNameOut = strdup(argv[2]);

  // Set input to specific file
  yyin = fopen(argv[1],"r");
  
  if (yyparse()==0)
    {
      /* Write bitcode to file with name argv[2] */
      LLVMWriteBitcodeToFile(Module,argv[2]);     
      return 0;
    }
  else 
    {
      printf("Error parsing file!\n");
      return 1;
    }

  return 0;
}
