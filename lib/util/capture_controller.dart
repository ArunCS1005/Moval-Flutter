import 'package:moval/api/urls.dart';

class CaptureController {

  static const _reUploadKey   = '_reUpload';
  static const _otherMediaKey = '_otherMedia';

  final Map<String, Function> _listener = {};

  CaptureController();

  invalidate(String key, Map item) {
    if(key == other) {
      _listener[_otherMediaKey]?.call('updateUi', item);
    } else {
      _listener[key]?.call();
    }
  }

  invalidateUpload(String key) {
    _listener[_reUploadKey]?.call(key);
  }

  invalidateOtherMedia(String task, Map item) {
    _listener[_otherMediaKey]?.call(task, item);
  }

  addListener(String key, Function() invalidate) {
    _listener[key] = invalidate;
  }

  removeListener(String key) {
    _listener.remove(key);
  }

  addUploadListener(Function(String key) reUpload) {
    _listener[_reUploadKey] = reUpload;
  }

  removeUploadListener() {
    _listener.remove(_reUploadKey);
  }

  addOtherMediaListener(Function(String task, Map item) otherMediaListener) {
    _listener[_otherMediaKey] = otherMediaListener;
  }

  removeOtherMediaListener() {
    _listener.remove(_otherMediaKey);
  }

}