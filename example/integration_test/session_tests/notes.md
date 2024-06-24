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
- Merge id reports session duration while no session started (M)
- Device id change without merge do not generate a request if it comes after a merge (CR,CG,M)
- Device id change without merge do not start a new session (CNR,A)
- 1 Location request seems to be missing at 206

## Things to consider

Android:
- later check override ID of an end session due to device ID change
- ID change (w/o merge) ends a session in manual mode too. Are we cool with that ?
