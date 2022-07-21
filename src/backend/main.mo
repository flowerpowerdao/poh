import List "mo:base/List";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";

import Canistergeek "mo:canistergeek/canistergeek";
import Modclub "mo:modsdk/modclub";

import Types "types";

shared ({ caller = init_minter}) actor class Whitelist() = this {
/*************
* CONSTANTS *
*************/

  let ENV = "staging";
  let whitelistSize = 3753;
  let canistergeekLogger = Canistergeek.Logger();

/****************
* STABLE STATE *
****************/

  stable var whitelist : TrieSet.Set<Principal> = TrieSet.empty();
  // principals in whitelist queue haven't provided POH on modclubs end yet, they will be redirected to modclubs site until
  // we receive the callback moving their principal to `whitelist`
  stable var queue : Trie.Trie<Principal, Text> = Trie.empty();
  // principals in this queue have completed POH, but it hasn't been reviewed by MODCLUB yet
  stable var pending : TrieSet.Set<Principal> = TrieSet.empty();
  // principals in blacklist can't complete POH and thus shouldnt trigger subsequent calls to 
  // `verifyHumanity`
  stable var blacklist : TrieSet.Set<Principal> = TrieSet.empty();

  // canistergeek
  stable var _canistergeekLoggerUD: ? Canistergeek.LoggerUpgradeData = null;
    
  system func preupgrade() {
    _canistergeekLoggerUD := ? canistergeekLogger.preupgrade();
  };

  system func postupgrade() { 
    canistergeekLogger.postupgrade(_canistergeekLoggerUD);
    _canistergeekLoggerUD := null;
  };

/******************
* PUBLIC METHODS *
******************/

  public shared(msg) func checkStatus() : async Result.Result<(), Types.CheckStatusError> {
    // check if whitelist is already full
    if(whitelistIsFullInternal()) {
      return #err(#whitelistIsFull)
    };
    // this principal is already whitelisted
    if (principalIsWhitelisted(msg.caller)) {
      return #err(#alreadyWhitelisted)
    // this principal already has a token and has to complete POH
    } else if (getTokenFromQueue(msg.caller) != null) {
      return #err(#pohNotCompleted)
    // this principal tried to link with a modclub account that already linked another principal
    } else if (principalIsBlacklisted(msg.caller)) {
      return #err(#principalBlacklisted)
    // this principal successfully submitted POH and it's status is pending
    } else if (principalIsPending(msg.caller)) {
      return #err(#pending)
    } else {
      // because the whitelist is a set we don't have to worry about atomicity in this case
      let response = await Modclub.getModclubActor(ENV).verifyHumanity(Principal.toText(msg.caller));
      canistergeekLogger.logMessage(
        "\ntype: checkStatus" # 
        "\nprincipal: " # response.providerUserId # 
        "\nstatus: " # debug_show(response.status) #
        "\nisFirstAssociation: " # debug_show(response.isFirstAssociation) #
        "\nrequestedAt: " # debug_show(response.requestedAt) #
        "\nsubmittedAt: " # debug_show(response.submittedAt) #
        "\ncompletedAt: " # debug_show(response.completedAt) #
        "\ntoken: " # debug_show(response.token) # "\n\n"
        );
      handlePohResponse(response, ?msg.caller)
    }
  };

  
  public shared (msg) func registerCallback() {
    assert(msg.caller == init_minter);
    await Modclub.getModclubActor(ENV).subscribePohCallback({callback});
  };

  public shared (msg) func callback(response: Modclub.PohVerificationResponsePlus) {
    assert(msg.caller == Principal.fromText(Modclub.getModclubId(ENV)));
      canistergeekLogger.logMessage(
        "\ntype: callback" # 
        "\nprincipal: " # response.providerUserId # 
        "\nstatus: " # debug_show(response.status) #
        "\nisFirstAssociation: " # debug_show(response.isFirstAssociation) #
        "\nrequestedAt: " # debug_show(response.requestedAt) #
        "\nsubmittedAt: " # debug_show(response.submittedAt) #
        "\ncompletedAt: " # debug_show(response.completedAt) #
        "\ntoken: " # debug_show(response.token) # "\n\n"
        );
    ignore handlePohResponse(response, null);
  };

  public shared query (msg) func whitelistIsFull() : async Bool {
    whitelistIsFullInternal()
  };

// canistergeek
  /**
  * Returns collected log messages based on passed parameters.
  * Called from browser.
  */
  public query ({caller}) func getCanisterLog(request: ?Canistergeek.CanisterLogRequest) : async ?Canistergeek.CanisterLogResponse {
    validateCaller(caller);
    canistergeekLogger.getLog(request);
  };
  
  private func validateCaller(principal: Principal) : () {
    assert( principal == Principal.fromText("ikywv-z7xvl-xavcg-ve6kg-dbbtx-wy3gy-qbtwp-7ylai-yl4lc-lwetg-kqe")) // canistergeek principal
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
    assert(msg.caller == init_minter);
    Trie.toArray<Principal, Text, (Principal,Text)>(queue, func (principal: Principal, token: Text) {return (principal,token)})
  };

  public shared query (msg) func getQueueQuery(): async [(Principal,Text)] {
    assert(msg.caller == init_minter);
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

  public shared(msg) func getPending(): async [Principal] {
    TrieSet.toArray(pending)
  };
  
  public shared query (msg) func getPendingQuery(): async [Principal] {
    TrieSet.toArray(pending)
  };

  public shared(msg) func isPending(principal: Principal) : async Bool {
    principalIsPending(principal)
  };

  public shared query (msg) func isPendingQuery(principal: Principal) : async Bool {
    principalIsPending(principal)
  };

  public shared(msg) func getToken() : async ?Text{
    getTokenFromQueue(msg.caller)
  };

  public shared(msg) func remainingSpots() : async Nat {
    whitelistSize - TrieSet.size(whitelist)
  };
  
/*******************
* PRIVATE METHODS *
*******************/

  func principalIsWhitelisted(principal : Principal) : Bool {
    TrieSet.mem<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func whitelistPrincipal(principal : Principal) {
    assert(whitelistIsFullInternal() == false);
    whitelist := TrieSet.put<Principal.Principal>(whitelist, principal, Principal.hash(principal), Principal.equal);
  };

  func whitelistIsFullInternal(): Bool {
    if (TrieSet.size(whitelist) >= whitelistSize) {
      return true
    } else {
      return false
    }
  };

  func principalIsBlacklisted(principal: Principal) : Bool {
    TrieSet.mem<Principal.Principal>(blacklist, principal, Principal.hash(principal), Principal.equal);
  };

  func blacklistPrinicpal(principal : Principal) {
    blacklist := TrieSet.put<Principal.Principal>(blacklist, principal, Principal.hash(principal), Principal.equal);
  };

  func principalIsPending(principal: Principal) : Bool {
    TrieSet.mem<Principal.Principal>(pending, principal, Principal.hash(principal), Principal.equal);
  };

  func addPrincipalToPending(principal : Principal) {
    pending:= TrieSet.put<Principal.Principal>(pending, principal, Principal.hash(principal), Principal.equal);
  };

  func deletePrincipalFromPending(principal : Principal) {
    pending := TrieSet.delete<Principal>(pending,principal, Principal.hash(principal), Principal.equal);
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
        // make sure we remove the principal from the queue and pending
        unqueuePrincipal(caller);
        deletePrincipalFromPending(caller);
        return #ok()
      };
      // this isn't the first association with the modclub account for this challenge
      case (false, _) {
        blacklistPrinicpal(caller);
        // make sure we remove the principal from the queue and pending
        unqueuePrincipal(caller);
        deletePrincipalFromPending(caller);
        return #err(#notFirstAssociation)
      };
      // poh was rejected
      case (_, #rejected) {
        blacklistPrinicpal(caller);
        // make sure we remove the principal from the queue and pending
        unqueuePrincipal(caller);
        deletePrincipalFromPending(caller);
        return #err(#pohRejected)
      };
      // poh was submitted
      case (_, #pending) {
        addPrincipalToPending(caller);
        // make sure we remove the principal from the queue
        unqueuePrincipal(caller);
        return #err(#pending)
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
            // make sure we remove the principal from the queue and pending
            unqueuePrincipal(caller);
            deletePrincipalFromPending(caller);
            return #err(#noTokenFound)
          }
        }
      };
    };
  }
};
