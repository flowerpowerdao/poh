import List "mo:base/List";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";

import Modclub "mo:modsdk/modclub";

import Types "types";

shared ({ caller = init_minter}) actor class Whitelist() = this {

  /****************
  * STABLE STATE *
  ****************/

  stable var whitelist : TrieSet.Set<Principal> = TrieSet.empty();

  /******************
  * PUBLIC METHODS *
  ******************/

  public shared(msg) func checkStatus() : async Result.Result<(), Types.CheckStatusError> {
    if (principalIsWhitelisted(msg.caller)) {
      return #err(#alreadyWhitelisted)
    };
    return #ok
  };

  public shared(msg) func getWhitelist(): async [Principal] {
    TrieSet.toArray(whitelist)
  };

  public shared(msg) func isWhitelisted(principal: Principal) : async Bool {
    principalIsWhitelisted(principal)
  };
  
  /*******************
  * PRIVATE METHODS *
  *******************/

  func principalIsWhitelisted(principal : Principal) : Bool {
    TrieSet.mem<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func whitelistPrincipal(principal : Principal, proposalHistory: List.List<Nat>) {
    whitelist := TrieSet.put<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };
};
