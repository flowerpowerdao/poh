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
    'pohAlreadyInitiated' : IDL.Null,
    'principalBlacklisted' : IDL.Null,
    'alreadyWhitelisted' : IDL.Null,
    'noTokenFound' : IDL.Null,
    'notFirstAssociation' : IDL.Null,
    'pohNotCompleted' : IDL.Null,
    'pohRejected' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : CheckStatusError });
  const Whitelist = IDL.Service({
    'callback' : IDL.Func([PohVerificationResponsePlus], [], ['oneway']),
    'checkStatus' : IDL.Func([], [Result], []),
    'getBlacklist' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getBlacklistQuery' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
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
    'getWhitelist' : IDL.Func([], [IDL.Vec(IDL.Principal)], []),
    'getWhitelistQuery' : IDL.Func([], [IDL.Vec(IDL.Principal)], ['query']),
    'isBlacklisted' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isBlacklistedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'isQueued' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isQueuedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'isWhitelisted' : IDL.Func([IDL.Principal], [IDL.Bool], []),
    'isWhitelistedQuery' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'registerCallback' : IDL.Func([], [], ['oneway']),
  });
  return Whitelist;
};
export const init = ({ IDL }) => { return []; };
