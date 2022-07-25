import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";

module {
  public type CheckStatusError = { 
    #alreadyWhitelisted; 
    #notFirstAssociation; 
    #pohRejected; 
    #noTokenFound; 
    #pohNotCompleted; 
    #principalBlacklisted;
    #pending;
    #whitelistIsFull;
    #whitelistNotStarted;
  };

  public func accountKey(t: Principal) : Trie.Key<Principal> = { key = t; hash = Principal.hash t };
}