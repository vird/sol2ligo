config = require("../src/config")
{
  translate_ligo_make_test : make_test
} = require("./util")


describe "translate ligo section", ()->
  @timeout 10000
  # ###################################################################################################
  #    stmt
  # ###################################################################################################
  it "if", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Ifer {
      uint public value;
      
      function ifer() public returns (uint) {
        uint x = 5;
        uint ret = 0;
        if (x == 5) {
          ret = value + x;
        }
        else  {
          ret = 0;
        }
        return ret;
      }
    }
    """
    text_o = """
    type state is record
      value : nat;
    end;
    
    function ifer (const opList : list(operation); const contractStorage : state) : (list(operation) * state * nat) is
      block {
        const x : nat = 5n;
        const ret : nat = 0n;
        if (x = 5n) then block {
          ret := (contractStorage.value + x);
        } else block {
          ret := 0n;
        };
      } with (opList, contractStorage, ret);
    
    """
    make_test text_i, text_o
  
  
  it "while", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Whiler {
      function whiler(address owner) public returns (int) {
        int i = 0;
        while(i < 5) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function whiler (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * int) is
      block {
        const i : int = 0;
        while (i < 5) block {
          i := (i + 1);
        };
      } with (opList, contractStorage, i);
    """
    make_test text_i, text_o
  
  # ###################################################################################################
  #    for
  # ###################################################################################################
  it "for", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function forer(address owner) public returns (int) {
        int i = 0;
        for(i=2;i < 5;i+=10) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function forer (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * int) is
      block {
        const i : int = 0;
        i := 2;
        while (i < 5) block {
          i := (i + 1);
          i := (i + 10);
        };
      } with (opList, contractStorage, i);
    """
    make_test text_i, text_o
  
  it "for no init", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function forer(address owner) public returns (int) {
        int i = 0;
        for(;i < 5;i+=10) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function forer (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * int) is
      block {
        const i : int = 0;
        while (i < 5) block {
          i := (i + 1);
          i := (i + 10);
        };
      } with (opList, contractStorage, i);
    """
    make_test text_i, text_o
  
  it "for no cond", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function forer(address owner) public returns (int) {
        int i = 0;
        for(i=2;;i+=10) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function forer (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * int) is
      block {
        const i : int = 0;
        i := 2;
        while (True) block {
          i := (i + 1);
          i := (i + 10);
        };
      } with (opList, contractStorage, i);
    """
    make_test text_i, text_o
  
  it "for no iter", ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function forer(address owner) public returns (int) {
        int i = 0;
        for(i=2;i < 5;) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      #{config.reserved}__empty_state : int;
    end;
    
    function forer (const opList : list(operation); const contractStorage : state; const owner : address) : (list(operation) * state * int) is
      block {
        const i : int = 0;
        i := 2;
        while (i < 5) block {
          i := (i + 1);
        };
      } with (opList, contractStorage, i);
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
