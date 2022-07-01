# add provider admin

- provide plug or stoic id principal or ii principal for staging
- cbvi-5yaaa-aaaah-qcopa-cai.raw.ic0.app

# after adding provider admin

- use trusted identity to configure POH, this can be done using ic scan for example

# interact with POH

- call verifyHumanity with principal of user as text
- response is PohVerificationResponsePlus
- when they havent submitted or started, token is present in this object
- redirect user to this page `https://ocbvi-5yaaa-aaaah-qcopa-cai.raw.ic0.app/#/new-poh-profile?token=<inputToken>&redirect_uri=<url-to-go-back-to app>`
- `isFirstAssociation` is true if this is the first time they are associating with this POH
