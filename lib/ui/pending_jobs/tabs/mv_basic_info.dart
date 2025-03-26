import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/local/local_outside.dart';
import 'package:moval/ui/pending_jobs/pending_jobs.dart';
import 'package:moval/ui/pending_jobs/widget/contact_info.dart';
import 'package:moval/ui/pending_jobs/widget/file_upload_failed.dart';
import 'package:moval/ui/pending_jobs/widget/location_warning.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/ui/util_ui/media_dialog.dart';
import 'package:moval/ui/util_ui/permission_dialog.dart';
import 'package:moval/util/capture_controller.dart';
import 'package:moval/util/location_controller.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/a_text.dart';
import 'package:moval/widget/button.dart';
import 'package:moval/widget/image_capture_field.dart';
import 'package:moval/widget/video_capture_field_.dart';
import 'package:moval/widget/edit_text.dart';
import 'package:moval/widget/more_media.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../api/api.dart';
import '../../../util/preference.dart';

class MVBasicInfo extends StatefulWidget {
  final PagerController _pagerController;

  const MVBasicInfo(this._pagerController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<MVBasicInfo>
    with AutomaticKeepAliveClientMixin<MVBasicInfo>, WidgetsBindingObserver {
  final Map _data = {};
  final CaptureController _captureController = CaptureController();
  final EditTextController _editTextController = EditTextController();
  final ScrollController _scrollController = ScrollController();
  String _loadDataApiResponse = Api.loading;
  static const MethodChannel _channel = MethodChannel("423u5.imageEdit");

  @override
  void initState() {
    _initiatePage();
    super.initState();
  }

  @override
  void dispose() {
    log('*** Dispose');
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _body();
  }

  _body() {
    switch (_loadDataApiResponse) {
      case Api.loading:
        return _loading;
      case Api.success:
        log('other media length---> ${Preference.getStr(Preference.otherImageLimit)}');
        log('other media length---> ${_getOtherMedia().length}');
        return _items;
      default:
        return _items;
    }
  }

  get _loading => const Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );

  get _items => Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              ContactInfo(
                _data,
                platform: platformTypeMV,
              ),
              const AText(
                "Upload The following photo",
                fontWeight: FontWeight.w500,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
              ),
              ImageCaptureField(
                  'Chassis number', _data, chassisNumber, _captureController),
              ImageCaptureField(
                  'Front view', _data, frontView, _captureController),
              ImageCaptureField(
                  'Rear view', _data, rearView, _captureController),
              ImageCaptureField(
                  'Right side', _data, rightSide, _captureController),
              ImageCaptureField(
                  'Left side', _data, leftSide, _captureController),
              ImageCaptureField(
                  'Odometer', _data, odometer, _captureController),
              if (_getOtherMedia().isNotEmpty)
                const AText(
                  "Other photo's",
                  fontWeight: FontWeight.w500,
                  padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
                ),
              MediaGridView(
                _getOtherMedia(),
                controller: _captureController,
                isEnable: _enableBasicInfo,
              ),
              if (_getOtherMedia().length <
                  (int.tryParse(
                          Preference.getStr(Preference.otherImageLimit)) ??
                      0))
                Button(
                  "Add more photos",
                  margin: EdgeInsets.only(
                    left: 20,
                    top: _getOtherMedia().isEmpty ? 45 : 15,
                    right: 20,
                    bottom: 30,
                  ),
                  onTap: _funAddMoreItem,
                  enable: _enableBasicInfo,
                ),
              VideoCaptureField(
                'Upload a Video of 30 Seconds',
                _data,
                video,
                _captureController,
                enable: _enableBasicInfo,
              ),
              const AText(
                "Add remark",
                fontWeight: FontWeight.w500,
                padding: EdgeInsets.fromLTRB(
                  20,
                  45,
                  20,
                  10,
                ),
              ),
              EditText(
                "Enter remark",
                'remark',
                _data,
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                lines: 2,
                enableShadow: true,
                controller: _editTextController,
                isEnable: _enableBasicInfo,
              ),
            ],
          ),
        ),
      );

  _scrollListener(double value) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    }
  }

  _funAddMoreItem() async {
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).requestFocus(FocusNode());

    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.location.request();

    var camera = await Permission.camera.status;
    var microphone = await Permission.microphone.status;
    var location = await Permission.locationWhenInUse.status;
    var gps = await Permission.locationWhenInUse.serviceStatus;

    if (camera.isGranted &&
        microphone.isGranted &&
        location.isGranted &&
        gps.isEnabled) {
      navigatorState.pushNamed(Routes.captureImage, arguments: {
        'title': 'Add more photos',
      }).then(_addMoreItemAdd);
    } else if (location.isGranted && gps.isDisabled) {
      showDialog(
          context: context,
          builder: (builder) => PermissionDialog(
                'Permission',
                'GPS enable required',
                'Open setting',
                onActionPosition: _openGPS,
              ));
    } else if (await Permission.camera.shouldShowRequestRationale) {
      await Permission.camera.request();
    } else if (await Permission.microphone.shouldShowRequestRationale) {
      await Permission.microphone.request();
    } else if (await Permission.location.shouldShowRequestRationale) {
      await Permission.location.request();
    } else {
      showDialog(
          context: context,
          builder: (builder) => PermissionDialog(
                'Permission',
                'Camera, microphone and location permission required',
                'Open setting',
                onActionPosition: _openAppSetting,
              ));
    }
  }

  _addMoreItemAdd(response) async {
    if (response == null) return;

    _images.add({
      'name': response['name'],
      'latitude': response['latitude'].toString(),
      'longitude': response['longitude'].toString(),
      'status': 'new',
      'type': other
    });

    _updateUi;
  }

  _otherMediaListener(String task, Map item) {
    switch (task) {
      case 'open':
        showDialog(
          context: context,
          builder: (builder) => MediaDialog(
            item['name'],
            picture: true,
          ),
        );
        break;
      case 'remove':
        if (!item['name'].startsWith('http')) File(item['name']).delete();
        _images.remove(item);
        _updateUi;
        break;
      case 'upload':
        _uploadFile(item);
        break;
      case 'updateUi':
        _updateUi;
        break;
    }
  }

  _openAppSetting() async {
    Navigator.pop(context);

    AppSettings.openAppSettings();
  }

  _openGPS() {
    Navigator.pop(context);

    AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    _captureController.addUploadListener(_reUploadListener);
    _captureController.addOtherMediaListener(_otherMediaListener);
    widget._pagerController.addResponseListener(basicInfo, _onResponse);
    widget._pagerController.addButtonListener(0, _next);
    widget._pagerController.addScrollListener(basicInfo, _scrollListener);
    widget._pagerController.addIdListener(basicInfo, (id) => _data['id'] = id);
  }

  _onResponse(response) async {
    if (response == Api.defaultError) {
      _loadDataApiResponse = Api.defaultError;
    } else {
      response.forEach((k, v) => _data[k] = v);
      _loadDataApiResponse = Api.success;
      _editTextController.invalidate('remark');
    }

    _updateUi;
  }

  _submitData() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    for (var item in _images) {
      if (item['status'] == Api.loading) return;
    }

    String files = '';

    for (var item in _images) {
      if ((item['status'] == Api.defaultError) &&
          !(item['type'] == video ||
              item['type'] == other ||
              item['name'].startsWith('http'))) {
        files = '${files.isEmpty ? '' : '$files, '}${item['type']}';
      }
    }

    if (files.isNotEmpty) {
      final response = await showDialog(
        context: context,
        builder: (builder) => FileUploadFailedDialog(
          files: files,
        ),
      );

      widget._pagerController.setButtonProgress(false);

      if (response == true) {
        _retryFailedFile();
      }

      return;
    }

    for (var item in _images) {
      if (item['status'] == Api.internetError &&
          !(item['type'] == video ||
              item['type'] == other ||
              item['name'].startsWith('http')) &&
          (double.parse(item['latitude']) == 0.0 ||
              double.parse(item['longitude']) == 0.0)) {
        ASnackBar.showError(scaffoldMessengerState,
            'Recapture image ${item['type']} due to location fetch error.');
        return;
      }
    }

    List otherImages = [];
    String videoPath = "";

    for (var image in _images) {
      if (image['type'] == other)
        otherImages
            .add(image['server'] ?? image['name'].split('storage/').last);
      if (image['type'] == video)
        videoPath = image['server'] ?? image['name'].split('storage/').last;
    }

    double lat = LocationController.position?.latitude ?? 0;
    double long = LocationController.position?.longitude ?? 0;
    String place = '';

    try {
      final placeMark = await placemarkFromCoordinates(lat, long);
      place = '${placeMark.first.subLocality}, ${placeMark.first.locality}';
    } catch (e) {
      log("Error in location fetch $e");
    } finally {
      LocalJobsStatus.saveJobLatLong(_data['id'], lat, long);

      String outside = await OutsideJob.getStatus(_data['id']);

      final response = await Api(scaffoldMessengerState).submitMVJobBasicInfo(
        jobId: _data['id'],
        remark: _getData('remark'),
        isOutside: outside,
        otherImages: otherImages,
        videoPath: videoPath,
        place: place,
        lat: lat.toString(),
        long: long.toString(),
      );

      log("Response $response");

      widget._pagerController.setButtonProgress(false);

      if (response.runtimeType == String &&
          response.startsWith(Api.defaultError)) {
        ASnackBar.showError(scaffoldMessengerState, response);
      } else if (response == Api.internetError) {
        _onJobSubmit(true);
      } else if (response == Api.authError) {
        UiUtils.authFailed(navigatorState);
      } else {
        _onJobSubmit(false);
      }
    }
  }

  _onJobSubmit(bool isOffline) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.basicInfo, isOffline);
    _localSaveJobBasicInfo;
    ASnackBar.showSnackBar(
        scaffoldMessengerState,
        isOffline
            ? 'Entered data & photos saved locally.'
            : 'Entered data & photos saved on server.',
        0,
        status: Api.success);
    await Future.delayed(const Duration(seconds: 1));
    widget._pagerController.navigate(1);
  }

  _next() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    if (widget._pagerController.buttonLoading) return;

    FocusScope.of(context).requestFocus(FocusNode());

    if (_getMedia(chassisNumber).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the chassis number is not clicked');
    } else if (_getMedia(frontView).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the front view is not clicked');
    } else if (_getMedia(rearView).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the rear view is not clicked');
    } else if (_getMedia(rightSide).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the right side is not clicked');
    } else if (_getMedia(leftSide).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the left side is not clicked');
    } else if (_getMedia(odometer).isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the odometer is not clicked');
    } else if (_getData('remark').isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the remark is not entered');
    } else {
      if (!_enableBasicInfo) {
        widget._pagerController.navigate(1);
        return;
      }

      widget._pagerController.setButtonProgress(true);

      if (await Api.networkAvailable() &&
          _getData('is_offline') == 'no' &&
          _imageLocationInvalid()) {
        showDialog(
            context: context, builder: (builder) => const LocationWarning());
        widget._pagerController.setButtonProgress(false);
        return;
      }

      if (_data['id'].isNegative) await widget._pagerController.createJob();

      _uploadMediaFile();
    }
  }

  bool _imageLocationInvalid() {
    int distance = 100;

    try {
      distance = int.parse('${_data['job_distance_filter']}');
    } catch (e) {
      log("-_-_____ ${e.toString()}}");
    }

    for (int a = 0; a < _images.length; a++) {
      for (int z = a + 1; z < _images.length; z++) {
        if (_getDistance(_images[a], _images[z]) > distance) {
          OutsideJob.saveStatus(_data['id'], 'Yes');
          return true;
        }
      }
    }

    return false;
  }

  double _getDistance(image1, image2) {
    double lat1 = double.parse(image1['latitude'] ?? '0.0');
    double lat2 = double.parse(image2['latitude'] ?? '0.0');
    double long1 = double.parse(image1['longitude'] ?? '0.0');
    double long2 = double.parse(image2['longitude'] ?? '0.0');

    if (lat1 == 0 || long1 == 0) {
      return -1;
    } else if (lat2 == 0 || long2 == 0) {
      return -2;
    } else {
      return Geolocator.distanceBetween(lat1, long1, lat2, long2);
    }
  }

  _reUploadListener(String key) {
    for (var item in _images) {
      if (item['type'] == key && item['status'] == 'retry') {
        _uploadFile(item);
        break;
      }
    }
  }

  _retryFailedFile() {
    for (var item in _images) {
      if (item['status'] != Api.success) {
        item['status'] = 'new';
      }
    }

    _next();
  }

  _uploadMediaFile() {
    bool pendingToUpload = false;

    for (var item in _images) {
      if (!(item['name'].startsWith('http') || item['status'] == Api.success)) {
        pendingToUpload = true;
        _uploadFile(item);
      }
    }

    if (!pendingToUpload) {
      _submitData();
    }
  }

  _uploadFile(Map item) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    item['status'] = Api.loading;
    _captureController.invalidate(item['type'], item);

    try {
      if (item['type'] != video && item['updated'] == '0') {
        final placeMark = await placemarkFromCoordinates(
          double.parse(item['latitude'] ?? '0'),
          double.parse(item['longitude'] ?? '0'),
        );

        String place =
            '${placeMark.first.subLocality}, ${placeMark.first.locality}';

        await _channel.invokeMethod(
          'edit',
          jsonEncode(
            {
              'path': item['name'],
              'location': '${item['time']}\n$place',
              'forcePortrait':
                  !(item['type'] == chassisNumber || item['type'] == odometer)
            },
          ),
        );
      }
    } catch (e) {
      log("When Adding Failed to get path $e");

      item['status'] = Api.internetError;
      _captureController.invalidate(item['type'], item);
      if (widget._pagerController.buttonLoading) {
        _submitData();
      }
      return;
    }

    String response = await Api(scaffoldMessengerState).uploadMVFile(
      jobId: _data['id'],
      type: item['type'],
      file: File(item['name']),
    );

    if (response.startsWith('job_files')) {
      await File(item['name']).delete();
      item['name'] = '$baseApiUrl/storage/$response';
      item['status'] = Api.success;
      item['server'] = response;
    } else {
      item['status'] = response;
    }

    _captureController.invalidate(item['type'], item);
    if (widget._pagerController.buttonLoading) {
      _submitData();
    }
  }

  String _getData(String key) => (_data[key] ?? '').toString();

  String _getMedia(String type) {
    for (var item in _images) {
      if (item['type'] == type) {
        return item['name'] ?? '';
      }
    }
    return '';
  }

  List _getOtherMedia() {
    List others = [];
    for (var item in _images) {
      if (item['type'] == other) {
        others.add(item);
      }
    }

    return others;
  }

  get _updateUi {
    if (!mounted) return;
    setState(() {});
  }

  get _enableBasicInfo =>
      _data['job_status'] == pending || _data['job_status'] == rejected;

  get _images => _data['images'];

  get _localSaveJobBasicInfo => LocalJobsDetail.updateJobBasicInfo(
      _data['id'], {'images': _images, 'remark': _getData('remark')});
}
