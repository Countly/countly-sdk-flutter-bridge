import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/countly_state.dart';

class ViewsInternal implements Views {
  ViewsInternal(this._cly, this._countlyState);

  final Countly _cly;
  final CountlyState _countlyState;

  @override
  void stopViewById(String viewID, Map<String, Object> segmentation) {}

  @override
  void stopLastView() {}

  @override
  void stopViewByName(String viewName, Map<String, Object> segmentation) {}

  @override
  String startView(String viewName, Map<String, Object> segmentation) {
    return '';
  }

  @override
  void setGlobalViewSegmentation(Map<String, Object> segmentation) {}

  @override
  void updateGlobalViewSegmentation(Map<String, Object> segmentation) {}
}
