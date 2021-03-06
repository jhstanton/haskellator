

module Main where

import           MIPs.Types
import           MIPs.Disassemble 

import           Language.Haskellator.Parse

import           Control.Applicative
import           Control.Monad.State
import           Data.Word
import           Data.Binary
import           Data.Binary.Get
import qualified Data.ByteString.Lazy as BS


rInstrFile :: FilePath
rInstrFile = "simple_r_instructions.bin"


main = do
  instrString            <- BS.readFile rInstrFile 
  let instructions       = runGet getInstructions instrString
  let parsedInstructions = fmap (runParser mkInstr) instructions
  putStrLn . disassemble . fmap fst $ parsedInstructions
--  mapM_ (putStrLn . show . fst) parsedInstructions

mkInstr :: Parser InstrWidth MInstruction
mkInstr = do 
  opBits <- getField 6
  let op = toOP opBits
  case op of
    R_op -> constructR 
    J_op -> constructJ op
    JAL  -> constructJ op
    _    -> constructI op
    

-- To get far enough to use these the first 6 bits will already be parsed (OP code field)
constructR :: Parser InstrWidth MInstruction 
constructR = R <$> getField 5 <*> getField 5 <*> getField 5 <*> getField 5 <*> (fmap toFunc $ getField 6)

constructI :: OP -> Parser InstrWidth MInstruction
constructI op = I op <$> getField 5 <*> getField 5 <*> getField 16

constructJ :: OP -> Parser InstrWidth MInstruction
constructJ op = J op <$> getField 26

getInstructions :: Get [InstrWidth]
getInstructions = do 
  empty <- isEmpty
  if empty
    then return []
    else do instr <- getWord32be
            next_instructions <- getInstructions 
            return (instr : next_instructions)
