import List "mo:base/List";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";

import Canistergeek "mo:canistergeek/canistergeek";
import Modclub "mo:modsdk/modclub";

import Types "types";

shared ({ caller = init_minter}) actor class Whitelist() = this {
/*************
* CONSTANTS *
*************/

  let ENV = "prod";
  let whitelistSize = 3872;
  let startDate = 1658844000000000000;
  let endDate =   1659103200000000000;
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

  
  // public shared (msg) func registerCallback() : async Text {
  //   assert(msg.caller == init_minter);
  //   let callbackStatus = await Modclub.getModclubActor(ENV).subscribePohCallback({callback});
  //   return debug_show(callbackStatus)
  // };

  public shared query(msg) func getOwner() : async Principal {
    return init_minter;
  };

  // public shared(msg) func setup () {
  //   let companyLogoInNat8Format : [Nat8] = [60,115,118,103,32,120,109,108,110,115,61,34,104,116,116,112,58,47,47,119,119,119,46,119,51,46,111,114,103,47,50,48,48,48,47,115,118,103,34,32,118,105,101,119,66,111,120,61,34,48,32,48,32,57,57,46,57,54,32,51,53,46,56,57,34,62,10,32,32,60,100,101,102,115,62,10,32,32,32,32,60,115,116,121,108,101,62,10,32,32,32,32,32,32,46,97,32,123,10,32,32,32,32,32,32,32,32,102,105,108,108,58,32,35,102,102,102,59,10,32,32,32,32,32,32,125,10,32,32,32,32,60,47,115,116,121,108,101,62,10,32,32,60,47,100,101,102,115,62,10,32,32,60,103,62,10,32,32,32,32,60,114,101,99,116,32,99,108,97,115,115,61,34,97,34,32,120,61,34,48,46,51,51,34,32,121,61,34,48,46,51,52,34,32,119,105,100,116,104,61,34,51,56,46,56,54,34,32,104,101,105,103,104,116,61,34,50,51,46,49,53,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,51,57,46,53,51,44,50,51,46,56,50,72,48,86,48,72,51,57,46,53,51,90,77,46,54,55,44,50,51,46,49,53,72,51,56,46,56,54,86,46,54,55,72,46,54,55,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,32,32,60,103,62,10,32,32,32,32,60,114,101,99,116,32,99,108,97,115,115,61,34,97,34,32,120,61,34,48,46,51,51,34,32,121,61,34,50,51,46,52,56,34,32,119,105,100,116,104,61,34,57,57,46,50,57,34,32,104,101,105,103,104,116,61,34,49,50,46,48,55,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,48,48,44,51,53,46,56,57,72,48,86,50,51,46,49,53,72,49,48,48,90,77,46,54,55,44,51,53,46,50,50,72,57,57,46,50,57,86,50,51,46,56,50,72,46,54,55,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,32,32,60,103,62,10,32,32,32,32,60,114,101,99,116,32,99,108,97,115,115,61,34,97,34,32,120,61,34,51,57,46,49,57,34,32,121,61,34,48,46,51,52,34,32,119,105,100,116,104,61,34,54,48,46,52,51,34,32,104,101,105,103,104,116,61,34,50,51,46,49,53,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,48,48,44,50,51,46,56,50,72,51,56,46,56,54,86,48,72,49,48,48,90,109,45,54,48,46,52,51,45,46,54,55,72,57,57,46,50,57,86,46,54,55,72,51,57,46,53,51,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,32,32,60,103,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,48,46,51,57,44,50,55,46,54,50,72,55,46,56,57,118,49,46,53,57,104,50,46,52,54,118,46,53,57,72,55,46,56,57,86,51,50,72,55,46,50,52,86,50,55,104,51,46,49,53,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,50,46,49,52,44,51,49,46,51,57,104,50,46,50,55,86,51,50,72,49,49,46,52,57,86,50,55,104,46,54,53,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,52,46,55,51,44,50,57,46,53,49,97,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,44,52,46,55,49,44,48,44,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,45,52,46,55,49,44,48,90,109,52,44,48,97,49,46,55,44,49,46,55,44,48,44,49,44,48,45,51,46,51,52,44,48,44,49,46,55,44,49,46,55,44,48,44,49,44,48,44,51,46,51,52,44,48,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,50,54,46,52,54,44,50,55,104,46,55,76,50,53,46,57,52,44,51,50,72,50,52,46,53,56,108,45,49,45,52,46,57,49,45,49,44,52,46,57,49,72,50,49,46,50,54,76,50,48,46,48,53,44,50,55,104,46,54,57,76,50,50,44,51,50,108,49,45,52,46,57,49,104,49,46,51,53,108,49,44,52,46,57,49,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,50,56,46,55,53,44,51,49,46,51,57,104,50,46,54,50,86,51,50,72,50,56,46,48,57,86,50,55,104,51,46,50,50,118,46,53,56,72,50,56,46,55,53,118,49,46,53,50,104,50,46,53,50,118,46,53,56,72,50,56,46,55,53,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,51,54,46,51,53,44,51,50,104,45,46,55,55,108,45,49,46,49,57,45,50,72,51,51,46,50,49,118,50,104,45,46,54,54,86,50,55,104,49,46,56,50,99,49,46,49,44,48,44,49,46,55,56,46,53,55,44,49,46,55,56,44,49,46,52,54,97,49,46,51,54,44,49,46,51,54,44,48,44,48,44,49,45,49,46,48,54,44,49,46,51,54,90,109,45,51,46,49,52,45,52,46,51,54,118,49,46,55,54,104,49,46,49,56,99,46,54,55,44,48,44,49,46,48,56,45,46,51,50,44,49,46,48,56,45,46,56,56,115,45,46,52,49,45,46,56,56,45,49,46,48,56,45,46,56,56,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,52,53,46,57,44,50,55,99,49,46,49,55,44,48,44,49,46,56,56,46,53,53,44,49,46,56,56,44,49,46,53,52,115,45,46,55,49,44,49,46,53,53,45,49,46,56,56,44,49,46,53,53,72,52,52,46,55,51,86,51,50,104,45,46,54,53,86,50,55,90,109,48,44,50,46,53,49,99,46,55,54,44,48,44,49,46,49,55,45,46,51,50,44,49,46,49,55,45,49,115,45,46,52,49,45,49,45,49,46,49,55,45,49,72,52,52,46,55,51,118,49,46,57,51,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,52,56,46,53,49,44,50,57,46,53,49,97,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,44,52,46,55,44,48,44,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,45,52,46,55,44,48,90,109,52,44,48,97,49,46,55,44,49,46,55,44,48,44,49,44,48,45,51,46,51,52,44,48,44,49,46,55,44,49,46,55,44,48,44,49,44,48,44,51,46,51,52,44,48,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,54,48,46,50,52,44,50,55,104,46,54,57,76,53,57,46,55,50,44,51,50,72,53,56,46,51,53,108,45,49,45,52,46,57,49,76,53,54,46,52,44,51,50,72,53,53,76,53,51,46,56,50,44,50,55,104,46,55,76,53,53,46,55,51,44,51,50,108,49,45,52,46,57,49,104,49,46,51,53,76,53,57,44,51,50,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,54,50,46,53,51,44,51,49,46,51,57,104,50,46,54,49,86,51,50,72,54,49,46,56,55,86,50,55,104,51,46,50,50,118,46,53,56,72,54,50,46,53,51,118,49,46,53,50,72,54,53,118,46,53,56,72,54,50,46,53,51,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,55,48,46,49,50,44,51,50,104,45,46,55,54,108,45,49,46,49,57,45,50,72,54,55,118,50,104,45,46,54,53,86,50,55,104,49,46,56,50,99,49,46,48,57,44,48,44,49,46,55,55,46,53,55,44,49,46,55,55,44,49,46,52,54,97,49,46,51,54,44,49,46,51,54,44,48,44,48,44,49,45,49,46,48,54,44,49,46,51,54,90,77,54,55,44,50,55,46,54,50,118,49,46,55,54,104,49,46,49,56,99,46,54,55,44,48,44,49,46,48,56,45,46,51,50,44,49,46,48,56,45,46,56,56,115,45,46,52,49,45,46,56,56,45,49,46,48,56,45,46,56,56,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,55,57,46,53,51,44,50,55,65,50,46,50,54,44,50,46,50,54,44,48,44,48,44,49,44,56,50,44,50,57,46,53,49,44,50,46,50,55,44,50,46,50,55,44,48,44,48,44,49,44,55,57,46,53,51,44,51,50,72,55,55,46,56,53,86,50,55,90,109,48,44,52,46,51,53,97,49,46,54,53,44,49,46,54,53,44,48,44,48,44,48,44,49,46,55,53,45,49,46,56,56,44,49,46,54,54,44,49,46,54,54,44,48,44,48,44,48,45,49,46,55,53,45,49,46,56,57,104,45,49,118,51,46,55,55,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,56,54,46,54,51,44,51,50,108,45,46,53,52,45,49,46,53,72,56,51,46,54,55,76,56,51,46,49,52,44,51,50,104,45,46,55,49,76,56,52,46,50,49,44,50,55,104,49,46,51,52,76,56,55,46,51,51,44,51,50,90,77,56,51,46,56,56,44,50,57,46,57,104,50,108,45,49,45,50,46,56,52,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,56,55,46,55,51,44,50,57,46,53,49,97,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,44,52,46,55,44,48,44,50,46,51,54,44,50,46,51,54,44,48,44,49,44,49,45,52,46,55,44,48,90,109,52,44,48,97,49,46,55,44,49,46,55,44,48,44,49,44,48,45,51,46,51,52,44,48,44,49,46,55,44,49,46,55,44,48,44,49,44,48,44,51,46,51,52,44,48,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,32,32,60,103,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,49,55,46,55,49,44,54,46,50,72,49,48,118,52,46,53,49,104,55,46,54,50,86,49,51,72,49,48,118,54,46,56,72,55,46,50,53,86,51,46,56,55,72,49,55,46,55,49,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,50,55,46,49,54,44,51,46,56,55,99,52,44,48,44,54,46,50,56,44,49,46,56,55,44,54,46,50,56,44,53,46,49,115,45,50,46,51,49,44,53,46,49,45,54,46,50,56,44,53,46,49,72,50,51,46,55,56,118,53,46,55,53,72,50,49,46,48,55,86,51,46,56,55,90,109,46,48,54,44,55,46,56,57,99,50,46,50,49,44,48,44,51,46,52,45,46,57,52,44,51,46,52,45,50,46,55,57,83,50,57,46,52,51,44,54,46,50,44,50,55,46,50,50,44,54,46,50,72,50,51,46,55,56,118,53,46,53,54,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,32,32,60,103,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,53,49,46,55,54,44,51,46,56,55,99,52,46,55,57,44,48,44,56,44,50,46,54,56,44,56,44,56,115,45,51,46,50,49,44,56,45,56,44,56,72,52,54,46,48,57,86,51,46,56,55,90,109,46,48,54,44,49,51,46,54,50,99,51,46,50,54,44,48,44,53,46,49,53,45,50,44,53,46,49,53,45,53,46,54,53,83,53,53,46,48,56,44,54,46,50,44,53,49,46,56,50,44,54,46,50,104,45,51,86,49,55,46,52,57,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,55,52,46,49,50,44,49,57,46,56,50,108,45,49,46,53,51,45,52,46,53,55,72,54,53,46,49,52,76,54,51,46,54,44,49,57,46,56,50,72,54,48,46,55,53,76,54,54,46,50,55,44,51,46,56,55,104,53,46,49,57,108,53,46,53,50,44,49,54,90,109,45,56,46,50,49,45,54,46,56,56,104,53,46,57,76,54,56,46,56,55,44,52,46,50,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,32,32,60,112,97,116,104,32,100,61,34,77,55,55,46,55,50,44,49,49,46,56,52,99,48,45,52,46,57,53,44,51,46,49,57,45,56,46,50,51,44,55,46,55,57,45,56,46,50,51,115,55,46,55,57,44,51,46,50,56,44,55,46,55,57,44,56,46,50,51,45,51,46,50,44,56,46,50,51,45,55,46,55,57,44,56,46,50,51,83,55,55,46,55,50,44,49,54,46,56,44,55,55,46,55,50,44,49,49,46,56,52,90,109,49,50,46,55,54,44,48,99,48,45,51,46,53,57,45,50,45,54,45,53,45,54,115,45,53,44,50,46,52,51,45,53,44,54,44,50,44,54,44,53,44,54,83,57,48,46,52,56,44,49,53,46,52,52,44,57,48,46,52,56,44,49,49,46,56,52,90,34,32,116,114,97,110,115,102,111,114,109,61,34,116,114,97,110,115,108,97,116,101,40,48,32,48,41,34,47,62,10,32,32,60,47,103,62,10,60,47,115,118,103,62,10];
  //   let companyLogo : Modclub.Image = {
  //       data = companyLogoInNat8Format;
  //       imageType = "image/svg+xml";
  //   };
  //   // Register with Modclub
  //   let _ = await Modclub.getModclubActor(ENV).registerProvider("FPDAO", "FPDAO provider", ?companyLogo);
  // };

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

  public shared query(msg) func remainingSpots() : async Nat {
    whitelistSize - TrieSet.size(whitelist)
  };

  public shared query(msg) func getWhitelistSize() : async Nat {
    whitelistSize
  };

  public shared query(msg) func whitelistHasStarted() : async Bool {
    Time.now() > startDate
  };

  public shared query(msg) func whitelistHasEnded() : async Bool {
    Time.now() > endDate
  };

  public shared query(msg) func getStartDate() : async Time.Time {
    startDate
  };

  public shared query(msg) func getEndDate() : async Time.Time {
    endDate
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
    if (Time.now() < startDate) {
      return #err(#whitelistNotStarted)
    };
    if (Time.now() > endDate) {
      return #err(#whitelistEnded)
    };
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
