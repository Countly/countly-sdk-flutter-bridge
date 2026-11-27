## Test that needs manual interaction
For iOS, currently as we don't have a way to trigger app foregraound action with code, the following tests need manual human interaction to go F/B when waiting log is printed:
200, 204, 207A

## Platform checks
As iOS SDK has no auto app start time tracking, the following tests has some platform checks verify different things:
201, 205

PS: This markdown was created for SDK version 24.1.0