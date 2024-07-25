* +--------------------------------------------------+--------------------------+---------+
* | SDK state at the end of the previous app session |   Configuration at init  |   Test  |
* +--------------------------------------------------+--------------------------+---------+
* |     Custom      |   SDK used a   |   Temp ID     |   Custom   |  Temporary  |         |
* |   device ID     |   generated    |   mode was    | device ID  |  device ID  |    No   |
* |    was set      |       ID       |   enabled     | provided   |  enabled    |         |
* +--------------------------------------------------+--------------------------+---------+
* |                     First init                   |      x     |      -      |    1    |
* +--------------------------------------------------+--------------------------+---------+
* |                     First init                   |      -     |      -      |    2    |
* +--------------------------------------------------+--------------------------+---------+
* |                     First init                   |      x     |      x      |    -    |
* +--------------------------------------------------+--------------------------+---------+
* |                     First init                   |      -     |      x      |    -    |
* +--------------------------------------------------+--------------------------+---------+

Init options:
BV:Bad Value
M:Manual Sessions enabled
A:Automatic sessions enabled
H:Hybrid Sessions enabled
CR:Consent Required
CNR:Consent not Required
CG:Session Consent given
CNG:Session Consent not given

## Anomalies

Android:
- enableTempID and setRequiresConsent. has 2 requests in event queue. iOS has none.
