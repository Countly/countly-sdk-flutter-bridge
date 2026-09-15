SDK Behavior Settings tests

And where to check values, which is affected:
from_server = FS
storage = S
provided = P
dev_provided = DP

200X tests are feature validation tests
where
A = SDK internal limits + Content Zone + Content Zone Interval + Refresh Content Zone + Backoff Mechanism Enabled
B = Tracking + Server Config Update Interval - will not affect SC request
C = Networking + Consent + Request Queue + Session Update Interval + Drop old request - will not affect SC request
D = Session Tracking + Custom Event Tracking + Event Queue + View Tracking + Location Tracking + Crash Tracking + Backoff Configs

Tests

- A
Call all features
Provide SBS from server {'lkl': 5, 'lvs': 5, 'lsv': 5, 'lbc': 5, 'ltlpt': 5, 'ltl': 5, 'rcz': false, 'ecz': true, 'czi': 16, 'bom': false, 'dort': 1}
Change all SDK internal limits and validate that all are applied
Store couple of requests before starting the SDK and show that they are deleted by drop request age
Trigger two requests that their response duration is above 10 seconds
Validate that:
- content zone is called after init
- provided zone timer interval is not default one and 16
- refresh content zone call is disabled
- backoff mechanism is disabled and two requests are passed
- validate the constraints for the backoff before sending requests

- B
Call all features
Provide SBS from server {'tracking': false, 'scui': 1}
Validate that:
- No requests exist in the sent requestArray in mock server
- RQ is empty
- Only SBS requests are existing
- Validate that next SBS fetch called in 1 hours

- C
Call all features
Provide SBS from storage {'networking': false, 'cr': true, 'rqs': 5, 'sui': 10}
Validate that:
- No requests exist in the sent requestArray in mock server
- RQ contains items
- Features that requires consent is not called and did not recorded things in RQ
- every 10 seconds session triggered

- D
Call all features
Provide SBS from server {'st': false, 'cet': false, 'vt': false, 'eqs': 5, 'lt': false, 'crt': false, 'bom_at': 5, 'bom_d': 30, 'bom_rqp': 0.01, 'bom_ra': 1}
Validate that:
- Session, custom events, location, crashes, views are not recorded
- Internal events are recorded and clipped by EQ limit
- Views are not affected by custom event tracking
- Backoff mechanism configs are applied

---------------------------------------------------------------------------------------------------------------------------------

201X tests order validation
where
- A
configure couple of internal limits in the CountlyConfig
Provide couple of internal limits in the provided SBS and return one internal limit from FS
Validate order is working and values applied
DP P FS Final
a        a
b. b1    b1
c. c1 c2 c2

- B
configure couple of internal limits in the CountlyConfig
Provide couple of internal limits in the stored SBS and return one internal limit from FS
Validate order is working and values applied
DP S FS Final
a        a
b. b1    b1
c. c1 c2 c2

- C
configure couple of internal limits in the CountlyConfig
Provide couple of internal limits in the provided SBS, stored SBS and return one internal limit from FS
Validate provided SBS is not applied because stored existing
Validate order is working and values applied
DP P  S  FS  Final
a            a
b. b1        b
c. c1 c2     c2
d. d1 d2 d3. d3

- D
configure couple of internal limits in the CountlyConfig and enable temporary id mode
Provide couple of internal limits in the provided SBS, stored SBS and return one internal limit from FS
Validate provided SBS is not applied because stored existing
Validate order is working and values applied
Also validate FS not fetched because temporary id mode
DP P  S  FS  Final
a            a
b. b1        b
c. c1 c2     c2
d. d1 d2 d3. d2

- E
configure couple of internal limits in the CountlyConfig and enable temporary id mode
Provide couple of internal limits in the provided SBS and return one internal limit from FS
Validate order is working and values applied
Validate FS not fetched because temporary id mode
DP P FS Final
a        a
b. b1    b1
c. c1 c2 c1

tests are:
- 201A_DP_P_FS
- 201B_DP_S_FS
- 201C_DP_P_S_FS
- 201D_DP_P_S_FS_temp_id
- 201E_DP_P_FS_temp_id

---------------------------------------------------------------------------------------------------------------------------------

202X tests value validation where:
Provide SBS from server:
```json
{
      'v': 1,
      't': 1750748806695,
      'c': {'lvs': 'hoho', 'lsv': 'hehe', 'lbc': -5, 'ltlpt': 0, 'unkown': 'very_unkown', 'ltl': 0, 'rcz': 'no', 'ecz': 'no', 'czi': -16, 'bom': 'test', 'dort': false, 'tracking': 'no', 'scui': 0.1, 'networking': 'yes', 'cr': '', 'rqs': -5, 'sui': -10}
    }
```

- A
Store SBS:
```json
{
      'v': 1,
      't': 1750748806695,
      'c': {'st': 'yes', 'cet': 'no', 'vt': 0, 'eqs': 0, 'unkown1': 'very_unkown1', 'lt': 1, 'crt': 'value', 'bom_at': -1, 'bom_d': -1, 'bom_rqp': 50, 'bom_ra': -1, 'lkl': 'test'}
    }
```
Validate that:
- Stored SBS at the end does not have any config values, only version and timestamp there.

- B
Provide SBS through configuration:
```json
{
      'v': 1,
      't': 1750748806695,
      'c': {'st': 'yes', 'cet': 'no', 'vt': 0, 'eqs': 0, 'unkown1': 'very_unkown1', 'lt': 1, 'crt': 'value', 'bom_at': -1, 'bom_d': -1, 'bom_rqp': 50, 'bom_ra': -1, 'lkl': 'test'}
    }
```
Validate that:
- Stored SBS at the end does not have any config values, only version and timestamp there.

tests are:
- 202A_S_FS
- 202B_P_FS

---------------------------------------------------------------------------------------------------------------------------------

200X continued - Filtering feature validation tests
where
E = Event Blacklist + Segmentation Blacklist + Event Segmentation Whitelist
F = User Property Blacklist + User Property Cache Limit + Journey Trigger Events + Content Zone
G = Event Whitelist + Segmentation Whitelist + Event Segmentation Blacklist + User Property Whitelist

- E
Call features and record events
Provide SBS from server {'eb': ['blocked_event', 'another_blocked'], 'sb': ['blocked_key', 'secret_key'], 'esw': {'filtered_event': ['allowed_key1', 'allowed_key2']}}
Validate that:
- Events in event blacklist are not recorded
- Segmentation keys in segmentation blacklist are removed from all events
- Event segmentation whitelist only allows listed keys for the specified event
- Non-filtered events and keys pass through normally

- F
Call features and record events
Provide SBS from server {'upb': ['blocked_prop', 'secret_prop'], 'upcl': 3, 'jte': ['journey_event'], 'ecz': true}
Validate that:
- User properties in user property blacklist are not sent
- Recording a journey trigger event causes content zone refresh
- Recording a non-journey event does NOT cause content zone refresh

- G
Call features and record events
Provide SBS from server {'ew': ['allowed_event', 'special_event'], 'sw': ['country', 'platform'], 'esb': {'special_event': ['platform']}, 'upw': ['name', 'email']}
Validate that:
- Only whitelisted events are recorded, all others are blocked
- Only whitelisted segmentation keys remain in events
- Event segmentation blacklist removes specific keys for specified event
- Only whitelisted user properties are sent

tests are:
- 200E (eb + sb + esw)
- 200F (upb + upcl + jte)
- 200G (ew + sw + esb + upw)

---------------------------------------------------------------------------------------------------------------------------------

202C - Filter mutual exclusivity + boundary validation
Store blacklists in storage, provide whitelists from server
Provide invalid boundary values from server (czi: 15, bom_rqp: 1.0, dort: -1)
Provide invalid filter types (eb: string, esb: string, jte: integer, upb: boolean)
Validate that:
- Whitelists from server override stored blacklists (mutual exclusivity)
- Invalid boundary values are rejected
- Invalid filter types are rejected

tests are:
- 202C

---------------------------------------------------------------------------------------------------------------------------------
Notes iOS:
In the base test iOS required more time then Android at the end
Because there is a probability for iOS to duplicate requests, checking request counts were not good
getAvaliableFeedbackWidgets= if no consent it broken iOS
iOS crash limits not applied to the stack traces
because health checks one of the earlier ones, in 200C if it was FS heath checks was sent because it runs before we fetch SBS.
Android has scrolls, content, star-rating, clicks consents extra
iOS reports all widget events directly but not android, android does not send rating report event immediately

validation things with base test