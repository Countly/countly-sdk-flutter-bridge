Server tests that tries the scenarios of server responses

All automatic calls are disabled to validate internal request triggering.

1. check 30 sec timeout works (request are not removed): (200)
2. check back off works (all conditions met):
    1. D |    |    : backs off (201A)
3. check back off not used (for each combination of conditions)
    2. D | FQ |    : - (201B)
    6. D |    | OR : - (201C)
    3. D | FQ | OR : - (201D)
    5.   | FQ | OR : - (202A)
    4.   | FQ |    : - (202B)
    7.   |    | OR : - (202C)
4. check base server works normally
    8.   |    |    : - (000)
 
condition combinations (response over 10 secs, queue over %50, request age over 24 hours):
delay = D
fullish queue = FQ
old req = OR

## Current Tests

- **BM_000_base_test.dart**: Verifies mock server operation and initial request queue handling.
- **BM_200_timeout_test.dart**: Ensures session request and events persist after 30-second server timeout.
- **BM_201A_backoff_D_test.dart**: Verifies backoff is applied when all backoff conditions are met (delay = 11s).
- **BM_201B_no_backoff_D_FQ_test.dart**: Checks backoff is skipped when queue is 50% or more full even if other conditions are satisfied.
- **BM_201C_no_backoff_D_OR_test.dart**: Ensures backoff is skipped if requests are older than 24 hours.
- **BM_201D_no_backoff_D_FQ_OR_test.dart**: Validates correct backoff behavior with a mix of old requests and fullish queue.
- **BM_202A_no_backoff_FQ_OR_test.dart**: Checks backoff is skipped when without a delay and FQ and OR.
- **BM_202B_no_backoff_FQ_test.dart**: Checks backoff is skipped when without a delay and FQ.
- **BM_202C_no_backoff_OR_test.dart**: Checks backoff is skipped when without a delay and OR.
