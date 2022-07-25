import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type CanisterLogFeature = { 'filterMessageByContains' : null } |
  { 'filterMessageByRegex' : null };
export interface CanisterLogMessages {
  'data' : Array<LogMessagesData>,
  'lastAnalyzedMessageTimeNanos' : [] | [Nanos],
}
export interface CanisterLogMessagesInfo {
  'features' : Array<[] | [CanisterLogFeature]>,
  'lastTimeNanos' : [] | [Nanos],
  'count' : number,
  'firstTimeNanos' : [] | [Nanos],
}
export type CanisterLogRequest = { 'getMessagesInfo' : null } |
  { 'getMessages' : GetLogMessagesParameters } |
  { 'getLatestMessages' : GetLatestLogMessagesParameters };
export type CanisterLogResponse = { 'messagesInfo' : CanisterLogMessagesInfo } |
  { 'messages' : CanisterLogMessages };
export interface ChallengeResponse {
  'status' : PohChallengeStatus,
  'completedOn' : [] | [bigint],
  'challengeId' : string,
}
export type CheckStatusError = { 'principalBlacklisted' : null } |
  { 'pending' : null } |
  { 'whitelistNotStarted' : null } |
  { 'whitelistIsFull' : null } |
  { 'alreadyWhitelisted' : null } |
  { 'noTokenFound' : null } |
  { 'notFirstAssociation' : null } |
  { 'pohNotCompleted' : null } |
  { 'pohRejected' : null };
export interface GetLatestLogMessagesParameters {
  'upToTimeNanos' : [] | [Nanos],
  'count' : number,
  'filter' : [] | [GetLogMessagesFilter],
}
export interface GetLogMessagesFilter {
  'analyzeCount' : number,
  'messageRegex' : [] | [string],
  'messageContains' : [] | [string],
}
export interface GetLogMessagesParameters {
  'count' : number,
  'filter' : [] | [GetLogMessagesFilter],
  'fromTimeNanos' : [] | [Nanos],
}
export interface LogMessagesData { 'timeNanos' : Nanos, 'message' : string }
export type Nanos = bigint;
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
export type Time = bigint;
export interface Whitelist {
  'callback' : ActorMethod<[PohVerificationResponsePlus], undefined>,
  'checkStatus' : ActorMethod<[], Result>,
  'getBlacklist' : ActorMethod<[], Array<Principal>>,
  'getBlacklistQuery' : ActorMethod<[], Array<Principal>>,
  'getCanisterLog' : ActorMethod<
    [[] | [CanisterLogRequest]],
    [] | [CanisterLogResponse],
  >,
  'getOwner' : ActorMethod<[], Principal>,
  'getPending' : ActorMethod<[], Array<Principal>>,
  'getPendingQuery' : ActorMethod<[], Array<Principal>>,
  'getQueue' : ActorMethod<[], Array<[Principal, string]>>,
  'getQueueQuery' : ActorMethod<[], Array<[Principal, string]>>,
  'getStartDate' : ActorMethod<[], Time>,
  'getToken' : ActorMethod<[], [] | [string]>,
  'getWhitelist' : ActorMethod<[], Array<Principal>>,
  'getWhitelistQuery' : ActorMethod<[], Array<Principal>>,
  'getWhitelistSize' : ActorMethod<[], bigint>,
  'isBlacklisted' : ActorMethod<[Principal], boolean>,
  'isBlacklistedQuery' : ActorMethod<[Principal], boolean>,
  'isPending' : ActorMethod<[Principal], boolean>,
  'isPendingQuery' : ActorMethod<[Principal], boolean>,
  'isQueued' : ActorMethod<[Principal], boolean>,
  'isQueuedQuery' : ActorMethod<[Principal], boolean>,
  'isWhitelisted' : ActorMethod<[Principal], boolean>,
  'isWhitelistedQuery' : ActorMethod<[Principal], boolean>,
  'registerCallback' : ActorMethod<[], string>,
  'remainingSpots' : ActorMethod<[], bigint>,
  'setup' : ActorMethod<[], undefined>,
  'whitelistHasStarted' : ActorMethod<[], boolean>,
  'whitelistIsFull' : ActorMethod<[], boolean>,
}
export interface _SERVICE extends Whitelist {}
