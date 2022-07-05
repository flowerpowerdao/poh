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
  stable var queue: Trie.Trie<Principal, Text> = Trie.empty();
  // principals in blacklist can't complete POH and thus shouldnt trigger subsequent calls to 
  // `verifyHumanity`
  stable var blacklist: TrieSet.Set<Principal> = TrieSet.empty();

/******************
* PUBLIC METHODS *
******************/

  public shared(msg) func checkStatus() : async Result.Result<(), Types.CheckStatusError> {
    // this principal is already whitelisted
    if (principalIsWhitelisted(msg.caller)) {
      return #err(#alreadyWhitelisted)
    // this principal already has a token and has to complete POH
    } else if (getTokenFromQueue(msg.caller) != null) {
      return #err(#pohAlreadyInitiated)
    // this principal tried to link with a modclub account that already linked another principal
    } else if (principalIsBlacklisted(msg.caller)) {
      return #err(#principalBlacklisted)
    }
    else {
      // because the whitelist is a set we don't have to worry about atomicity in this case
      let response = await Modclub.getModclubActor(ENV).verifyHumanity(Principal.toText(msg.caller));
      handlePohResponse(response, ?msg.caller)
    }
  };

  
  public shared (msg) func registerCallback() {
    assert(msg.caller == init_minter);
    await Modclub.getModclubActor(ENV).subscribePohCallback({callback});
  };

  public shared (msg) func callback(response: Modclub.PohVerificationResponsePlus) {
    assert(msg.caller == Principal.fromText(Modclub.getModclubId(ENV)));
    ignore handlePohResponse(response, null);
  };



// getters
  public shared(msg) func getWhitelist(): async [Principal] {
    TrieSet.toArray(whitelist)
  };
  
  public shared query (msg) func getWhitelistQuery(): async [Principal] {
    TrieSet.toArray(whitelist)
  };

  public shared(msg) func isWhitelisted(principal: Principal) : async Bool {
    principalIsWhitelisted(principal)
  };

  public shared query (msg) func isWhitelistedQuery(principal: Principal) : async Bool {
    principalIsWhitelisted(principal)
  };
  
  public shared(msg) func getBlacklist(): async [Principal] {
    TrieSet.toArray(blacklist)
  };
  
  public shared query (msg) func getBlacklistQuery(): async [Principal] {
    TrieSet.toArray(blacklist)
  };

  public shared(msg) func isBlacklisted(principal: Principal) : async Bool {
    principalIsBlacklisted(principal)
  };

  public shared query (msg) func isBlacklistedQuery(principal: Principal) : async Bool {
    principalIsBlacklisted(principal)
  };

  public shared(msg) func getQueue(): async [(Principal,Text)] {
    Trie.toArray<Principal, Text, (Principal,Text)>(queue, func (principal: Principal, token: Text) {return (principal,token)})
  };

  public shared query (msg) func getQueueQuery(): async [(Principal,Text)] {
    Trie.toArray<Principal, Text, (Principal,Text)>(queue, func (principal: Principal, token: Text) {return (principal,token)})
  };

  public shared(msg) func isQueued(principal: Principal) : async Bool {
    switch (getTokenFromQueue(principal)) {
      case (?token) {
        return true
      };
      case (_) {
        return false
      }
    }
  };

  public shared query (msg) func isQueuedQuery(principal: Principal) : async Bool {
    switch (getTokenFromQueue(principal)) {
      case (?token) {
        return true
      };
      case (_) {
        return false
      }
    }
  };

  public shared(msg) func getToken() : async ?Text{
    getTokenFromQueue(msg.caller)
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

  func principalIsBlacklisted(principal: Principal) : Bool {
    TrieSet.mem<Principal.Principal>(blacklist, principal, Principal.hash(principal), Principal.equal);
  };

  func blacklistPrinicpal(principal : Principal) {
    blacklist := TrieSet.put<Principal.Principal>(blacklist, principal, Principal.hash(principal), Principal.equal);
  };

  func getTokenFromQueue(principal : Principal) : ?Text {
    Trie.get(queue, Types.accountKey(principal), Principal.equal)
  };

  func queuePrincipal(principal : Principal, token: Text) {
    queue := Trie.put(queue , Types.accountKey(principal), Principal.equal, token).0;
  };

  func unqueuePrincipal(principal : Principal) {
    queue := Trie.remove<Principal, Text>(queue, Types.accountKey(principal), Principal.equal).0;
  };

  func handlePohResponse(response: Modclub.PohVerificationResponsePlus, principal: ?Principal) : Result.Result<(), Types.CheckStatusError> {
    var caller : Principal = Principal.fromText("2vxsx-fae");
    switch (principal) {
      // if the method is called from within this canister, a caller principal is provided
      case (?principal) {
        caller := principal;
      };
      // if the method is called from the callback, no caller is provided
      case (_) {
        caller := Principal.fromText(response.providerUserId);
      }
    };

    switch (response.isFirstAssociation, response.status) {
      // user has successfully verified his first principal
      case (true, #verified) {
        whitelistPrincipal(caller);
        // make sure we remove the principal from the queue
        unqueuePrincipal(caller);
        return #ok()
      };
      // this isn't the first association with the modclub account for this challenge
      case (false, _) {
        blacklistPrinicpal(caller);
        return #err(#notFirstAssociation)
      };
      // poh was rejected
      case (_, #rejected) {
        blacklistPrinicpal(caller);
        return #err(#pohRejected)
      };
      // poh hasn't been completed yet
      case (_, _) {
        switch (response.token) {
          case (?token) {
            queuePrincipal(caller, token);
            #err(#pohNotCompleted)
          };
          // if we can't find a token we blacklist the caller as a safeguard
          // because the token should always be present
          case (_) {
            blacklistPrinicpal(caller);
            return #err(#noTokenFound)
          }
        }
      };
    };
  }
};
