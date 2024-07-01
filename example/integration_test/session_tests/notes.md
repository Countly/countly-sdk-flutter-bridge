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
- Device id change without merge do not start a new session (CNR_A)
- 1 Location request seems to be missing at 206
- has scrolls, clicks, star-rating consent (ios dont)

iOS:
- Change ID without merge does not end a session (CNR_M)
- no location req (203)
- no orientation req (205)
- check if app to fg starts session (204)
- 206: no consent req. we cool?