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

  it "main test", ()->
    text_i = """
    pragma solidity ^0.4.16;

    contract UnOpTest {
        function main(bool b0) internal {
            bool b1 = !!!!!b0;
        }
    }
    """
    text_o = """
    type state is record
      #{config.empty_state} : int;
    end;

    function #{config.reserved}__main (const opList : list(operation); const contractStorage : state; const b0 : bool) : (list(operation) * state) is
      block {
        const b1 : bool = not (not (not (not (not (b0)))));
      } with (opList, contractStorage);
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
      #{config.empty_state} : int;
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
      #{config.empty_state} : int;
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
  #     #{config.empty_state} : int;
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
  #    pure
  # ###################################################################################################
  it "pure decl + router", ()->
    text_i = """
    pragma solidity ^0.4.22;
    
    contract Pure_test {
      function test() public pure returns (uint) {
        return 0;
      }
    }
    """#"
    text_o = """
    type test_args is record
      callbackAddress : address;
    end;
    
    type state is record
      #{config.initialized} : bool;
    end;
    
    function test (const #{config.reserved}__unit : unit) : (nat) is
      block {
        skip
      } with (0n);
    
    type router_enum is
      | Test of test_args;
    
    function main (const action : router_enum; const contractStorage : state) : (list(operation) * state) is
      block {
        const opList : list(operation) = (nil: list(operation));
        if (contractStorage.#{config.initialized}) then block {
          case action of
          | Test(match_action) -> block {
            const tmp_0 : nat = test(unit);
            opList := cons(transaction(tmp_0, 0mutez, (get_contract(match_action.callbackAddress) : contract(nat))), opList);
          }
          end;
        } else block {
          contractStorage.#{config.initialized} := True;
        };
      } with (opList, contractStorage);
    """#"
    make_test text_i, text_o, router: true
  
  it "pure call + router", ()->
    text_i = """
    pragma solidity ^0.4.22;
    
    contract Pure_test {
      function exactAdd(uint self, uint other) internal pure returns (uint sum) {
        sum = self + other;
        require(sum >= self);
      }
      function test() public pure returns (uint) {
        var n = uint(~0);
        exactAdd(n,1);
        return 0;
      }
    }
    """#"
    text_o = """
    type test_args is record
      callbackAddress : address;
    end;
    
    type state is record
      #{config.initialized} : bool;
    end;
    
    function exactAdd (const self : nat; const other : nat) : (nat) is
      block {
        const sum : nat = 0n;
        sum := (self + other);
        if (sum >= self) then {skip} else failwith("require fail");
      } with (sum);
    
    function test (const #{config.reserved}__unit : unit) : (nat) is
      block {
        const n : nat = abs(not (0));
        const tmp_0 : nat = exactAdd(n, 1n);
      } with (0n);
    
    type router_enum is
      | Test of test_args;
    
    function main (const action : router_enum; const contractStorage : state) : (list(operation) * state) is
      block {
        const opList : list(operation) = (nil: list(operation));
        if (contractStorage.#{config.initialized}) then block {
          case action of
          | Test(match_action) -> block {
            const tmp_0 : nat = test(unit);
            opList := cons(transaction(tmp_0, 0mutez, (get_contract(match_action.callbackAddress) : contract(nat))), opList);
          }
          end;
        } else block {
          contractStorage.#{config.initialized} := True;
        };
      } with (opList, contractStorage);
    """#"
    make_test text_i, text_o, router: true
  
  