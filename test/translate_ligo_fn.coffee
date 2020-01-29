config = require "../src/config"
{
  translate_ligo_make_test : make_test
} = require("./util")

describe "translate ligo section", ()->
  @timeout 10000
  # ###################################################################################################
  #    basic
  # ###################################################################################################
  it "hello world", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Hello_world {
      uint public value;
      
      function test() public {
        value = 1;
      }
    }
    """
    text_o = """
    type state is record
      value : nat;
    end;
    
    function test (const opList : list(operation); const contractStorage : state) : (list(operation) * state) is
      block {
        contractStorage.value := 1n;
      } with (opList, contractStorage);
    
    """
    make_test text_i, text_o
  
  # ###################################################################################################
  #    fn decl special abilities
  # ###################################################################################################
  it "named ret val", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Expr {
      uint public value;
      
      function expr() public returns (int c) {
        int a = 0;
        c = a;
        return c;
      }
    }
    """
    text_o = """
    type state is record
      value : nat;
    end;
    
    function expr (const opList : list(operation); const contractStorage : state) : (list(operation) * state * int) is
      block {
        const c : int = 0;
        const a : int = 0;
        c := a;
      } with (opList, contractStorage, c);
    """
    make_test text_i, text_o
  
  it "named ret val no return", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Expr {
      uint public value;
      
      function expr() public returns (int c) {
        int a = 0;
        c = a;
      }
    }
    """
    text_o = """
    type state is record
      value : nat;
    end;
    
    function expr (const opList : list(operation); const contractStorage : state) : (list(operation) * state * int) is
      block {
        const c : int = 0;
        const a : int = 0;
        c := a;
      } with (opList, contractStorage, c);
    """
    make_test text_i, text_o
  
  # ###################################################################################################
  #    fn call
  # ###################################################################################################
  it "fn decl, ret", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Call {
      function test() public returns (uint) {
        return 0;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function test (const opList : list(operation); const contractStorage : state) : (list(operation) * state * nat) is
      block {
        skip
      } with (opList, contractStorage, 0n);
    """
    make_test text_i, text_o
  
  it "fn call", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Call {
      function call_me(int a) public returns (int) {
        return a;
      }
      function test(int a) public returns (int) {
        return call_me(a);
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function call_me (const opList : list(operation); const contractStorage : state; const a : int) : (list(operation) * state * int) is
      block {
        skip
      } with (opList, contractStorage, a);
    
    function test (const opList : list(operation); const contractStorage : state; const a : int) : (list(operation) * state * int) is
      block {
        const tmp_0 : (list(operation) * state * int) = call_me(opList, contractStorage, a);
        opList := tmp_0.0;
        contractStorage := tmp_0.1;
      } with (opList, contractStorage, tmp_0.2);
    """
    make_test text_i, text_o
  
  it "fn call in expr", ()->
    text_i = """
    pragma solidity ^0.5.0;
    
    contract Ownable {
        function _msgSender() internal view returns (address payable) {
            return msg.sender;
        }
        address private _owner;
        
        function isOwner() public view returns (bool) {
            return _msgSender() == _owner;
        }
    }
    """#"
    text_o = """
    type state is record
      #{config.fix_underscore}__owner : address;
    end;
    
    function #{config.fix_underscore}__msgSender (const opList : list(operation); const contractStorage : state) : (list(operation) * state * address) is
      block {
        skip
      } with (opList, contractStorage, sender);
    
    function isOwner (const opList : list(operation); const contractStorage : state) : (list(operation) * state * bool) is
      block {
        const tmp_0 : (list(operation) * state * address) = #{config.fix_underscore}__msgSender(opList, contractStorage);
        opList := tmp_0.0;
        contractStorage := tmp_0.1;
      } with (opList, contractStorage, (tmp_0.2 = contractStorage.#{config.fix_underscore}__owner));
    """
    make_test text_i, text_o
  
  # it "fn call and after decl", ()->
  #   text_i = """
  #   pragma solidity ^0.5.11;
  #   
  #   contract Call {
  #     function test(int a) public returns (int) {
  #       return call_me(a);
  #     }
  #     function call_me(int a) public returns (int) {
  #       return a;
  #     }
  #   }
  #   """#"
  #   text_o = """
  #   type state is record
  #     #{config.reserved}__empty_state : int;
  #   end;
  #   
  #   function test (const opList : list(operation); const contractStorage : state; const a : int) : (list(operation) * state * int) is
  #     block {
  #       const tmp_0 : (list(operation) * state * int) = call_me(opList, contractStorage, a);
  #       opList := tmp_0.0;
  #       contractStorage := tmp_0.1;
  #     } with (opList, contractStorage, tmp_0.2);
  #   
  #   function call_me (const opList : list(operation); const contractStorage : state; const a : int) : (list(operation) * state * int) is
  #     block {
  #       skip
  #     } with (opList, contractStorage, a);
  #   """
  #   make_test text_i, text_o
  
  # ###################################################################################################
  #    global fn
  # ###################################################################################################
  
  it "asserts", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Asserts {
      function asserts() public {
        uint tokenCount = 4;
        require(tokenCount < 5, "Sample text");
        assert(tokenCount == 4);
      }
    }
    """#"
    text_o = """
    type state is record
      reserved__empty_state : int;
    end;
    
    function asserts (const opList : list(operation); const contractStorage : state) : (list(operation) * state) is
      block {
        const tokenCount : nat = 4n;
        if (tokenCount < 5n) then {skip} else failwith("Sample text");
        if (tokenCount = 4n) then {skip} else failwith("require fail");
      } with (opList, contractStorage);
    """#"
    make_test text_i, text_o
  
  it "require", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Require_test {
      mapping (address => uint) balances;
      
      function test(address owner) public returns (uint) {
        require(balances[owner] >= 0, "Overdrawn balance");
        return 0;
      }
    }
    """#"
    text_o = """
    type state is record
      balances : map(address, nat);
    end;
    
    function test (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * nat) is
      block {
        if ((case contractStorage.balances[owner] of | None -> 0n | Some(x) -> x end) >= 0n) then {skip} else failwith("Overdrawn balance");
      } with (opList, contractStorage, 0n);
    """#"
    make_test text_i, text_o
  
  it "require 0.4", ()->
    text_i = """
    pragma solidity >=0.4.21;
    
    contract Require_test {
      mapping (address => uint) balances;
      
      function test(address owner) public returns (uint) {
        require(balances[owner] >= 0);
        return 0;
      }
    }
    """#"
    text_o = """
    type state is record
      balances : map(address, nat);
    end;
    
    function test (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * nat) is
      block {
        if ((case contractStorage.balances[owner] of | None -> 0n | Some(x) -> x end) >= 0n) then {skip} else failwith("require fail");
      } with (opList, contractStorage, 0n);
    """#"
    make_test text_i, text_o
  