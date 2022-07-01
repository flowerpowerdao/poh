export const idlFactory = ({ IDL }) => {
  const Whitelist = IDL.Service({ 'setup' : IDL.Func([], [IDL.Text], []) });
  return Whitelist;
};
export const init = ({ IDL }) => { return []; };
