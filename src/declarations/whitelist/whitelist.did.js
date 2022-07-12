export const idlFactory = ({ IDL }) => {
  const PohVerificationStatus = IDL.Variant({
    'notSubmitted' : IDL.Null,
    'verified' : IDL.Null,
    'expired' : IDL.Null,
    'pending' : IDL.Null,
    'startPoh' : IDL.Null,
    'rejected' : IDL.Null,
  });
  const PohChallengeStatus = IDL.Variant({
    'notSubmitted' : IDL.Null,
    'verified' : IDL.Null,
    'expired' : IDL.Null,
    'pending' : IDL.Null,
    'rejected' : IDL.Null,
  });
  const ChallengeResponse = IDL.Record({
    'status' : PohChallengeStatus,
    'completedOn' : IDL.Opt(IDL.Int),
    'challengeId' : IDL.Text,
  });
  const PohVerificationResponsePlus = IDL.Record({
    'status' : PohVerificationStatus,
    'completedAt' : IDL.Opt(IDL.Int),
    'token' : IDL.Opt(IDL.Text),
    'rejectionReasons' : IDL.Vec(IDL.Text),
    'submittedAt' : IDL.Opt(IDL.Int),
    'isFirstAssociation' : IDL.Bool,
    'providerId' : IDL.Principal,
    'challenges' : IDL.Vec(ChallengeResponse),
    'requestedAt' : IDL.Opt(IDL.Int),
    'providerUserId' : IDL.Text,
  });
  const CheckStatusError = IDL.Variant({
    'principalBlacklisted' : IDL.Null,
    'pending' : IDL.Null,
    'whitelistIsFull' : IDL.Null,
    'alreadyWhitelisted' : IDL.Null,
    'noTokenFound' : IDL.Null,
    'notFirstAssociation' : IDL.Null,
    'pohNotCompleted' : IDL.Null,
    'pohRejected' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : CheckStatusError });
  const GetLogMessagesFilter = IDL.Record({
    'analyzeCount' : IDL.Nat32,
    'messageRegex' : IDL.Opt(IDL.Text),
    'messageContains' : IDL.Opt(IDL.Text),
  });
  const Nanos = IDL.Nat64;
  const GetLogMessagesParameters = IDL.Record({
    'count' : IDL.Nat32,
    'filter' : IDL.Opt(GetLogMessagesFilter),
    'fromTimeNanos' : IDL.Opt(Nanos),
  });
  const GetLatestLogMessagesParameters = IDL.Record({
    'upToTimeNanos' : IDL.Opt(Nanos),
    'count' : IDL.Nat32,
    'filter' : IDL.Opt(GetLogMessagesFilter),
  });
  const CanisterLogRequest = IDL.Variant({
    'getMessagesInfo' : IDL.Null,
    'getMessages' : GetLogMessagesParameters,
    'getLatestMessages' : GetLatestLogMessagesParameters,
  });
  const CanisterLogFeature = IDL.Variant({
    'filterMessageByContains' : IDL.Null,
    'filterMessageByRegex' : IDL.Null,
  });
  const CanisterLogMessagesInfo = IDL.Record({
    'features' : IDL.Vec(IDL.Opt(CanisterLogFeature)),
    'lastTimeNanos' : IDL.Opt(Nanos),
    'count' : IDL.Nat32,
    'firstTimeNanos' : IDL.Opt(Nanos),
  });
  const LogMessagesData = IDL.Record({
    'timeNanos' : Nanos,
    'message' : IDL.Text,
  });
  const CanisterLogMessages = IDL.Record({
    'data' : IDL.Vec(LogMessagesData),
    'lastAnalyzedMessageTimeNanos' : IDL.Opt(Nanos),
  });
  const CanisterLogResponse = IDL.Variant({
    'messagesInfo' : CanisterLogMessagesInfo,
    'messages' : CanisterLogMessages,
  });
  const Whitelist = IDL.Service({
    'callback' : IDL.Func([PohVerificationResponsePlus], [], ['oneway']),
    'checkStatus' : IDL.Func([], [Result], []),
    'getBlacklist' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getBlacklistQuery' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'getCanisterLog' : IDL.Func(
        [IDL.Opt(CanisterLogRequest)],
        [IDL.Opt(CanisterLogResponse)],
        ['query'],
      ),
    'getPending' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getPendingQuery' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'getQueue' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Text))],
        [],
      ),
    'getQueueQuery' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Text))],
        ['query'],
      ),
    'getToken' : IDL.Func([], [IDL.Opt(IDL.Text)], []),
    'getWhitelist' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getWhitelistQuery' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'isBlacklisted' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isBlacklistedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'isPending' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isPendingQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'isQueued' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isQueuedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'isWhitelisted' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isWhitelistedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'registerCallback' : IDL.Func([], [], ['oneway']),
    'whitelistIsFull' : IDL.Func([], [IDL.Bool], ['query']),
  });
  return Whitelist;
};
export const init = ({ IDL }) => { return []; };
