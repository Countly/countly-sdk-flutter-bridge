## Some observations
in iOS segmentation truncation limit is applied only on string data types for both key and value not sure about Android
in iOS segmentation values provided in events/views are converted to string but in startautostoppedview and global view segmentation its is not, it should be consistent for all cases
in iOS for apm_metrics, if we provide an integer, it will convert it in to string
in iOS view visit and start is convert to integer from string.
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