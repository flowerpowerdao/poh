import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";

module {
  public type CheckStatusError = { #alreadyWhitelisted }
}