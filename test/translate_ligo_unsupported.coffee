assert = require "assert"
config = require "../src/config"
{
  translate_ligo_make_test : make_test
} = require("./util")

describe "translate ligo section", ()->
  @timeout 10000
  # ###################################################################################################
  #    there are no support in LIGO
  # ###################################################################################################
  # NOTE this test will produce invalid code, that will compile with Ligo 
  it "UNSUPPORTED break continue", ()->
    text_i = """
    pragma solidity ^0.5.0;
    
    contract Recursive_test {
      function test() public {
        while(false) {
          break;
          continue;
        }
      }
    }
    """
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function test (const opList : list(operation); const contractStorage : state) : (list(operation) * state) is
      block {
        while (False) block {
          (* CRITICAL WARNING break is not supported *);
          (* CRITICAL WARNING continue is not supported *);
        };
      } with (opList, contractStorage);
    """#"
    make_test text_i, text_o, allow_need_prevent_deploy:true
  
  # NOTE this test will not compile with Ligo
  it "ecrecover", ()->
    text_i = """
    pragma solidity ^0.5.0;
    
    contract ECDSA {
      function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) pure public returns (address) {
        return ecrecover(hash, v, r, s);
      }
    }
    """
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function recover (const hash : bytes; const v : nat; const r : bytes; const s : bytes) : (address) is
      block {
        const tmp_0 : address = ecrecover(hash, v, r, s);
      } with (tmp_0);
    """#"
    make_test text_i, text_o, no_ligo:true
  
