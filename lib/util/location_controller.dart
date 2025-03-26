import 'dart:developer';

import 'package:geolocator/geolocator.dart';

class LocationController {

  static Position? _position;

  static Position? get position => _position;

  static final List _streams   = [];

  static Function(bool isShow)? _gpsDialogHandler;
  static bool dialogShowing = false;

  static updatePosition(Position? position) {
    LocationController._position = position;
    _gpsDialogHandler?.call(false);
    _streams.add({'l1' : position?.latitude, 'l2' : position?.longitude, 'l3' : position?.accuracy});
    //log("Location update ${_position?.latitude} ${_position?.longitude}");
    log("Stream delta ${streamsDelta()}");
  }


  static onError(value) {
    log("Error when getting location");
    _gpsDialogHandler?.call(true);
  }

  static onGPSChange(value) {
    if (value.toString() == 'ServiceStatus.enabled' && dialogShowing) {
      _gpsDialogHandler?.call(false);
    } else if(value.toString() == 'ServiceStatus.disabled' && !dialogShowing) {
      _gpsDialogHandler?.call(true);
    }
  }

  static addGPSDialogHandler(Function(bool) listener) => _gpsDialogHandler = listener;

  static String streamsDelta() {
    if(_streams.isEmpty) return 'NO DATA FOUND';
    Map first = _streams.first;
    String data = '';
    for(int a = 1; a < _streams.length; a++) {
      data = '${data.isEmpty ? '' : '$data\n'}'
          '${Geolocator.distanceBetween(first['l1'], first['l2'], _streams[a]['l1'], _streams[a]['l2'])}';
    }
    return data;
  }

}