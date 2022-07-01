import List "mo:base/List";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";

import Modclub "mo:modsdk/modclub";

import Types "types";

shared ({ caller = init_minter}) actor class Whitelist() = this {
  /*************
  * CONSTANTS *
  *************/

  let ENV = "staging";

  /****************
  * STABLE STATE *
  ****************/

  stable var whitelist : TrieSet.Set<Principal> = TrieSet.empty();
  // principals in whitelist queue haven't provided POH on modclubs end yet, they will be redirected to modclubs site until
  // we receive the callback moving their principal to `whitelist`
  stable var whitelistQueue : Trie.Trie<Principal, Text> = Trie.empty();
  // principals in notFirstAssociation have been associated with 
  stable var notFirstAssociation: TrieSet.Set<Principal> = TrieSet.empty();

  /******************
  * PUBLIC METHODS *
  ******************/

  public shared(msg) func checkStatus() : async Result.Result<(), Types.CheckStatusError> {
    // this principal is already whitelisted
    if (principalIsWhitelisted(msg.caller)) {
      return #err(#alreadyWhitelisted)
    // this principal already has a token and has to complete POH
    } else if (getWhitelistQueue(msg.caller) != null) {
      return #err(#pohAlreadyInitiated)
    // this principal tried to link with a modclub account that already linked another principal
    } else if (principalIsNotFirstAssociation(msg.caller)) {
      return #err(#pohAlreadyUsedForDifferentPrincipal)
    }
    else {
      // because the whitelist is a set we don't have to worry about atomicity in this case
      let response = await Modclub.getModclubActor(ENV).verifyHumanity(Principal.toText(msg.caller));
      switch (response.isFirstAssociation, response.status) {
        // user has successfully verified his first principal
        case (true, #verified) {
          whitelistPrincipal(msg.caller);
          return #ok()
        };
        case (false, #verified) {
          notFirstAssociationPrincipal(msg.caller);
          return #err(#notFirstAssociation)
        };
        case (_, #startPoh) {

        };
        case (_, #notSubmitted) {

        };
        case (_, #expired) {

        };
        case (_, _) {

        }
      };
      return #ok
    }
  };

  public shared(msg) func getWhitelist(): async [Principal] {
    TrieSet.toArray(whitelist)
  };

  public shared(msg) func isWhitelisted(principal: Principal) : async Bool {
    principalIsWhitelisted(principal)
  };
  
  public shared (msg) func registerCallback() {

  };
  
  /*******************
  * PRIVATE METHODS *
  *******************/

  func principalIsWhitelisted(principal : Principal) : Bool {
    TrieSet.mem<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func whitelistPrincipal(principal : Principal) {
    whitelist := TrieSet.put<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func principalIsNotFirstAssociation(principal: Principal) : Bool {
    TrieSet.mem<Principal.Principal>(notFirstAssociation, principal, Principal.hash(principal), Principal.equal);
  };

  func notFirstAssociationPrincipal(principal : Principal) {
    whitelist := TrieSet.put<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func getWhitelistQueue(principal : Principal) : ?Text {
    Trie.get(whitelistQueue, Types.accountKey(principal), Principal.equal)
  };

  func putWhitelistQueue(principal : Principal, token: Text) {
    whitelistQueue := Trie.put(whitelistQueue, Types.accountKey(principal), Principal.equal, token).0;
  };
};
