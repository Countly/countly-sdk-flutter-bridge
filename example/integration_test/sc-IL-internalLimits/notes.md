## Some observations
recordView records segmentation values as string (autoStoppedView does not)
reportfeedbackwidgetmanually prints weird things

## Platform issues
Android:
setMaxSegmentationValues key-value pairs not capped for:
- Global view segmentation
setMaxValueSize is not truncating for:
- Anything except breadcrumbs
setMacKeyLength is not truncating for:
- Anything

iOS:
setMaxSegmentationValues key-value pairs not capped for:
setMaxValueSize is not truncating for:
setMacKeyLength is not truncating for:
