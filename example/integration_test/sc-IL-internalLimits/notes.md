## Some observations
recordView records segmentation values as string (autoStoppedView does not)
reportfeedbackwidgetmanually prints/logs weird things
in ios user profile and its manipulation is different requests
in ios breadcrumbs has an extra date added: "_logs":"<2024-04-02 15:09:21.483> User Performed Step A\n<2024-04-02 15:09:21.511> User Performed Step A"

## Platform issues
Android:
setMaxSegmentationValues:
- Global view segmentation count not capped
setMaxValueSize:
- Only truncates breadcrumb
setMaxKeyLength:
- Not working

iOS:
setMaxSegmentationValues:
- Custom trace segmentation count not capped
- Custom crash segmentation count not capped
- View internal segmentation key/value pairs also included in capping
- Custom user details count not capped
setMaxValueSize:
- Not truncating custom segmentation values
- Not truncating breadcrumbs
- Truncating internal view segmentation values (like 'iOS')
- Not truncating userData operation values
setMaxKeyLength:
- Truncating internal event keys (like '[CLY_view]')
- Truncating internal view segmentation keys (like 'start')
- userData operation keys not truncated
- Custom crash segmentation keys not truncated
