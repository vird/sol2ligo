type transfer_args is record
  recipient : address;
  value : nat;
end;

type balanceOf_args is record
  receiver : contract(unit);
  account : address;
end;

type state is record
  balances : map(address, nat);
end;

type router_enum is
  | Transfer of transfer_args
  | BalanceOf of balanceOf_args;

function transfer (const self : state; const recipient : address; const value : nat) : (list(operation) * state) is
  block {
    self.balances[sender] := abs((case self.balances[sender] of | None -> 0n | Some(x) -> x end) - value);
    self.balances[recipient] := ((case self.balances[recipient] of | None -> 0n | Some(x) -> x end) + value);
  } with ((nil: list(operation)), self);

function balanceOf (const self : state; const receiver : contract(unit); const account : address) : (list(operation)) is
  block {
    skip
  } with ((nil: list(operation)));

function main (const action : router_enum; const self : state) : (list(operation) * state) is
  (case action of
  | Transfer(match_action) -> transfer(self, match_action.recipient, match_action.value)
  | BalanceOf(match_action) -> (balanceOf(self, match_action.receiver, match_action.account), self)
  end);
