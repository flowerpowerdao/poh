import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface ChallengeResponse {
  'status' : PohChallengeStatus,
  'completedOn' : [] | [bigint],
  'challengeId' : string,
}
export type CheckStatusError = { 'pohAlreadyInitiated' : null } |
  { 'principalBlacklisted' : null } |
  { 'alreadyWhitelisted' : null } |
  { 'noTokenFound' : null } |
  { 'notFirstAssociation' : null } |
  { 'pohNotCompleted' : null } |
  { 'pohRejected' : null };
export type PohChallengeStatus = { 'notSubmitted' : null } |
  { 'verified' : null } |
  { 'expired' : null } |
  { 'pending' : null } |
  { 'rejected' : null };
export interface PohVerificationResponsePlus {
  'status' : PohVerificationStatus,
  'completedAt' : [] | [bigint],
  'token' : [] | [string],
  'rejectionReasons' : Array<string>,
  'submittedAt' : [] | [bigint],
  'isFirstAssociation' : boolean,
  'providerId' : Principal,
  'challenges' : Array<ChallengeResponse>,
  'requestedAt' : [] | [bigint],
  'providerUserId' : string,
}
export type PohVerificationStatus = { 'notSubmitted' : null } |
  { 'verified' : null } |
  { 'expired' : null } |
  { 'pending' : null } |
  { 'startPoh' : null } |
  { 'rejected' : null };
export type Result = { 'ok' : null } |
  { 'err' : CheckStatusError };
export interface Whitelist {
  'callback' : ActorMethod<[PohVerificationResponsePlus], undefined>,
  'checkStatus' : ActorMethod<[], Result>,
  'getBlacklist' : ActorMethod<[], Array<Principal>>,
  'getBlacklistQuery' : ActorMethod<[], Array<Principal>>,
  'getQueue' : ActorMethod<[], Array<[Principal, string]>>,
  'getQueueQuery' : ActorMethod<[], Array<[Principal, string]>>,
  'getWhitelist' : ActorMethod<[], Array<Principal>>,
  'getWhitelistQuery' : ActorMethod<[], Array<Principal>>,
  'isBlacklisted' : ActorMethod<[Principal], boolean>,
  'isBlacklistedQuery' : ActorMethod<[Principal], boolean>,
  'isQueued' : ActorMethod<[Principal], boolean>,
  'isQueuedQuery' : ActorMethod<[Principal], boolean>,
  'isWhitelisted' : ActorMethod<[Principal], boolean>,
  'isWhitelistedQuery' : ActorMethod<[Principal], boolean>,
  'registerCallback' : ActorMethod<[], undefined>,
}
export interface _SERVICE extends Whitelist {}
