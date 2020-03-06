// t4.cpp

#include <stdlib.h>
#include <stdio.h>

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;

static LLVMContext TheContext;

int main (int argc, char ** argv)
{  
  /* Build global Module, this will be what we output */
  Module *M = new Module("Tutorial4", TheContext);

  IRBuilder<> Builder(TheContext);

  // Create void function type with no arguments
  FunctionType *FunType = FunctionType::get(Builder.getVoidTy(),false);

  Function *F = Function::Create(FunType,GlobalValue::ExternalLinkage, "main", M);

  BasicBlock *entry = BasicBlock::Create(TheContext, "entry", F);
  Builder.SetInsertPoint(entry);

  // Build for-loop here!
  BasicBlock *forcond = BasicBlock::Create(TheContext, "for.cond", F);
  BasicBlock *forbody = BasicBlock::Create(TheContext, "for.body", F);
  BasicBlock *forexit = BasicBlock::Create(TheContext, "for.exit", F);

  Builder.CreateBr(forcond);
  Builder.SetInsertPoint(forcond);

  PHINode *phi_i = Builder.CreatePHI(Builder.getInt64Ty(),2);

  Builder.CreateCondBr(Builder.CreateICmpSLT(phi_i,Builder.getInt64(10)),
                      forbody,
                      forexit);
  
  Builder.SetInsertPoint(forbody);
  Value * add = Builder.CreateAdd(phi_i,
                                Builder.getInt64(1),
                                "iplus1");
  Builder.CreateBr(forcond);

  Builder.SetInsertPoint(forexit);
  Builder.CreateRetVoid();

  phi_i->addIncoming(Builder.getInt64(0),entry);
  //phi_i->addIncoming(add,forbody);

  
  errs() << "All users of the instruction: \n";

  using use_iterator = Value::use_iterator;
  
  for(use_iterator u = add->use_begin(); u!=add->use_end(); u++)
    {
      Value *v = u->getUser();
      v->print(errs(),true);
      errs() << "\n";
    }

  Instruction *add_inst = cast<Instruction>(add);
  
  // Note: the cast<> template will perform some error checking to 
  // make sure the cast is sane, that add really is an 
  // Instruction object. If not, it will return nullptr.
  
  // For C++ boffins, you should prefer LLVM’s cast<> over the C++ 
  // standard static_cast<> to get the extra LLVM specific checks.

  for(unsigned op=0; op < add_inst->getNumOperands(); op++) 
    {
      Value* def = add_inst->getOperand(op);
      errs() << "Definition of op=" << op << " is:" ;
      def->print(errs(),true);
      errs() << "\n";

      // PHINode *phi = cast<PHINode>(def);
      // if (phi != nullptr)
      // 	{
      // 	  errs() << "I got a pointer to a PHINode!\n";
      // 	}
      if ( isa<PHINode> (def) )
	{
	  errs() << "It's a PHINode!\n";

	  PHINode *phi = cast<PHINode>(def);
	  
	}
      else if ( isa<Constant>(def) ) {
	errs() << "It's constant!\n";
	
      }
      else
	{
	  errs() << "It's not!\n";
	}
      
    } 


  verifyModule(*M, &errs());
  
  // Print module to screen
  //M->print(errs(),nullptr);

 //Write module to file
 std::error_code EC;
 raw_fd_ostream OS("main.bc",EC,sys::fs::F_None);   
 WriteBitcodeToFile(*M,OS);

  /* Return an error status if it failed */
  return 0;
}


