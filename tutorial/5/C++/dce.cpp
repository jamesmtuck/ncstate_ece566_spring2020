// dce.cpp

#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <set>

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

#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"

using namespace llvm;

void NoOptimization(Module &M) 
{
   // Do nothing! Simplest optimization that exists
}

bool isDead(Instruction &I)
{
  int opcode = I.getOpcode();
  switch(opcode){
  case Instruction::Add:
  case Instruction::FNeg:
  case Instruction::FAdd: 	
  case Instruction::Sub:
  case Instruction::FSub: 	
  case Instruction::Mul:
  case Instruction::FMul: 	
  case Instruction::UDiv:	
  case Instruction::SDiv:	
  case Instruction::FDiv:	
  case Instruction::URem: 	
  case Instruction::SRem: 	
  case Instruction::FRem: 	
  case Instruction::Shl: 	
  case Instruction::LShr: 	
  case Instruction::AShr: 	
  case Instruction::And: 	
  case Instruction::Or: 	
  case Instruction::Xor: 	
  case Instruction::Alloca:
  case Instruction::GetElementPtr: 	
  case Instruction::Trunc: 	
  case Instruction::ZExt: 	
  case Instruction::SExt: 	
  case Instruction::FPToUI: 	
  case Instruction::FPToSI: 	
  case Instruction::UIToFP: 	
  case Instruction::SIToFP: 	
  case Instruction::FPTrunc: 	
  case Instruction::FPExt: 	
  case Instruction::PtrToInt: 	
  case Instruction::IntToPtr: 	
  case Instruction::BitCast: 	
  case Instruction::AddrSpaceCast: 	
  case Instruction::ICmp: 	
  case Instruction::FCmp: 	
  case Instruction::PHI: 
  case Instruction::Select: 
  case Instruction::ExtractElement: 	
  case Instruction::InsertElement: 	
  case Instruction::ShuffleVector: 	
  case Instruction::ExtractValue: 	
  case Instruction::InsertValue: 
    if ( I.use_begin() == I.use_end() )
      {
	return true;
      }    
    break;

  case Instruction::Load:
    {
      LoadInst *li = dyn_cast<LoadInst>(&I);
      if (li->isVolatile())
	return false;

      if ( I.use_begin() == I.use_end() )
	{
	  return true;
	}
      
      break;
    }
  
  default: // any other opcode fails (includes stores and branches)
    // we don't know about this case, so conservatively fail!
    return false;
  }
  
  return false;
}

static int DCE_count = 0;

void RunDeadCodeElimination(Module &M)
{
 
  for(auto f = M.begin(); f!=M.end(); f++)       // loop over functions

    {
      std::set<Instruction*> worklist;

      for(auto bb= f->begin(); bb!=f->end(); bb++)
	{
	  // loop over basic blocks
	  for(auto i = bb->begin(); i != bb->end(); i++)
	    {
	      //loop over instructions
	      if (isDead(*i)) {
		//add I to a worklist to replace later
		worklist.insert(&*i);
	      }
	      
	      
	    }
	}

      while(worklist.size()>0) 
	{
	  // Get the first item 
	  Instruction *i = *(worklist.begin());
	  // Erase it from worklist
	  worklist.erase(i);
	  
	  if(isDead(*i))
	    {
	      for(unsigned op=0; op<i->getNumOperands(); op++)
		{
		  // Note, op still has one use (in i) so the isDead routine
		  // would return false, so we’d better not check that yet.
		  // This forces us to check in the if statement above.
		  
		  
		  
		  // The operand could be many different things, in 
		  // particular constants. Don’t try to delete them
		  // unless they are an instruction:
		  if ( isa<Instruction>(i->getOperand(op)) ) 
		    {
		      Instruction *o = 
			dyn_cast<Instruction>(i->getOperand(op));
		      worklist.insert(o);
		    }
		}
	      i->eraseFromParent();
	      DCE_count++;
	    }
	  
	}
    }

  

  std::cout << "DCE_Count = " << DCE_count << std::endl;

}

// Or, more idiomatic for C++, use auto to make it more concise



int main (int argc, char ** argv)
{  
  if (argc < 3) {
    fprintf(stderr,"Not enough positional arguments to %s.\n",argv[0]);
    return 1;
  }

  std::string InputFilename(argv[1]);
  std::string OutputFilename(argv[2]);

  // LLVM idiom for constructing output file.
  std::unique_ptr<ToolOutputFile> Out;  
  std::string ErrorInfo;
  std::error_code EC;
  Out.reset(new ToolOutputFile(argv[2], EC,
  				 sys::fs::F_None));

  SMDiagnostic Err;
  std::unique_ptr<Module> M;
  LLVMContext *Context = new LLVMContext();
  M = parseIRFile(InputFilename, Err, *Context);

  if (M.get() == 0) {
    Err.print(argv[0], errs());
    return 1;
  }

  /* 3. Do optimization on Module */
  //NoOptimization(*M.get());
  
  RunDeadCodeElimination(*M.get());

  //M->print(errs(),nullptr);

  bool res = verifyModule(*M, &errs());
  if (!res) {
    WriteBitcodeToFile(*M.get(),Out->os());
    Out->keep();
  } else {
    fprintf(stderr,"Error: %s not created.\n",argv[2]); 
  }

  return 0;
}


