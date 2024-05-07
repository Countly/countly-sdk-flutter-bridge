## Some observations
recordView records segmentation values as string (autoStoppedView does not)
reportfeedbackwidgetmanually prints/logs weird things
in ios user profile and its manipulation is different requests
in ios breadcrumbs has an extra date added: "_logs":"<2024-04-02 15:09:21.483> User Performed Step A\n<2024-04-02 15:09:21.511> User Performed Step A"

## Platform issues
Android:
setMaxSegmentationValues:
- custom user properties has no limit
setMaxValueSize:
- truncates user property `picture` (not picture path)
setMaxKeyLength:
- Network Trace name not truncated

iOS:
setMaxValueSize:
- Not truncating userData operation values (setOnce, push, pull, pushUnique)