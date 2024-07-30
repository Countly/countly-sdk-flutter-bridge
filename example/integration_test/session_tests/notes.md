Init options:
M:Manual Sessions enabled
A:Automatic sessions enabled
H:Hybrid Sessions enabled
CR:Consent Required
CNR:Consent not Required
CG:Session Consent given
CNG:Session Consent not given

## Anomalies

Android:
- Device id change without merge do not start a new session (CNR_A) => i guess fixed but lets check
- has scrolls, clicks, star-rating consent (ios dont) => it is what it is
- orientation doc should state it is on by default, why it works at bg/fg

iOS:
- no location req (203) => ios should send empty location req when consent revoked and also we init with no consent
- no orientation req (205) => this should work normally, why not at bg/fg
- 206: no consent given request while CR_CNG => should send consents are false request

- check if app to fg starts session (204) => we adding a fix