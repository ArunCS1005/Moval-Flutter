import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/local/local_outside.dart';
import 'package:moval/ui/pending_jobs/pending_jobs.dart';
import 'package:moval/ui/pending_jobs/widget/contact_info.dart';
import 'package:moval/ui/pending_jobs/widget/location_warning.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/ui/util_ui/media_dialog.dart';
import 'package:moval/util/capture_controller.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/a_text.dart';
import 'package:moval/widget/button.dart';
import 'package:moval/widget/image_capture_field.dart';
import 'package:moval/widget/edit_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../api/api.dart';
import '../../../../util/job_submit_service.dart';
import '../../../../util/routes.dart';
import '../../../../widget/video_capture_field_.dart';
import '../../../util_ui/permission_dialog.dart';



class MSUploadImages extends StatefulWidget {
  final PagerController _pagerController;

  const MSUploadImages(this._pagerController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<MSUploadImages>
    with AutomaticKeepAliveClientMixin<MSUploadImages>, WidgetsBindingObserver {
  final Map _data = {};
  final Map _dataSOP = {};
  final CaptureController _captureController = CaptureController();
  final EditTextController _editTextController = EditTextController();
  final ScrollController _scrollController = ScrollController();
  String _loadDataApiResponse = Api.loading;
  static const MethodChannel _channel = MethodChannel("423u5.imageEdit");

  List get _vehicleImagesFieldLabel =>
      _dataSOP['vehichle_images_field_label'] ?? [];

  List get _customVehicleImagesField => _images
      .where((e) => e['section'] == 'custom_vehichle_images_field_post')
      .toList();

  List get _documentImageFieldLabel =>
      _dataSOP['document_image_field_label'] ?? [];

  List get _customDocumentImageField => _images
      .where((e) => e['section'] == 'custom_document_images_field_post')
      .toList();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initiatePage();
    });
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
        return _items;
      default:
        return const Center(child: Text('Internet Error'));
    }
  }

  get _vehicleImageItems {
    return _vehicleImagesFieldLabel.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AText(
                "Upload Images",
                fontWeight: FontWeight.w500,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
              ),
              Column(
                children: _vehicleImagesFieldLabel.map((e) {
                  String label = e['form_field_label'] ?? '';
                  if (label.isEmpty) return const SizedBox.shrink();
                  return ImageCaptureField(
                    label,
                    _data,
                    label,
                    _captureController,
                    isAIEnabled: true,
                    onMediaSaved: (dynamic item) {
                      if (item['name'].startsWith('http') ||
                          item['status'] == Api.success) return;
                      _uploadFile(item);
                    },
                  );
                }).toList(),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  get _customVehicleImageItems {
    return _customVehicleImagesField.isNotEmpty
        ? Column(
            children: _customVehicleImagesField.map((e) {
              String label = e['type'] ?? '';
              if (label.isEmpty) return const SizedBox.shrink();
              return ImageCaptureField(
                label,
                _data,
                label,
                _captureController,
                isAIEnabled: true,
                onMediaRemoved: (item) {
                  _images.removeWhere((e) => e['type'] == item['type']);
                  _updateUi;
                },
              );
            }).toList(),
          )
        : const SizedBox.shrink();
  }

  get _documentImageItems {
    return _documentImageFieldLabel.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AText(
                "Upload Documents",
                fontWeight: FontWeight.w500,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
              ),
              Column(
                children: _documentImageFieldLabel.map((e) {
                  String label = e['form_document_label'] ?? '';
                  if (label.isEmpty) return const SizedBox.shrink();
                  return ImageCaptureField(
                    label,
                    _data,
                    label,
                    addDate: false,
                    _captureController,
                    onMediaSaved: (dynamic item) {
                      if (item['name'].startsWith('http') ||
                          item['status'] == Api.success) return;
                      _uploadFile(item);
                    },
                  );
                }).toList(),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  get _customDocumentImageItems {
    return _customDocumentImageField.isNotEmpty
        ? Column(
            children: _customDocumentImageField.map((e) {
              String label = e['type'] ?? '';
              if (label.isEmpty) return const SizedBox.shrink();
              return ImageCaptureField(
                label,
                _data,
                label,
                _captureController,
                onMediaRemoved: (item) {
                  _images.removeWhere((e) => e['type'] == item['type']);
                  _updateUi;
                },
              );
            }).toList(),
          )
        : const SizedBox.shrink();
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
                platform: platformTypeMS,
              ),
              const SizedBox(
                height: 20,
              ),
              _vehicleImageItems,
              _customVehicleImageItems,
              Button(
                "Add more vehicle photos",
                margin: const EdgeInsets.only(
                  left: 20,
                  top: 20,
                  right: 20,
                  bottom: 10,
                ),
                onTap: () {
                  _funAddMoreItem(key: 'custom_vehichle_images_field_post');
                },
                enable: _enableBasicInfo,
              ),
              const SizedBox(
                height: 20,
              ),
              _documentImageItems,
              _customDocumentImageItems,
              Button(
                "Add more document photos",
                margin: const EdgeInsets.only(
                  left: 20,
                  top: 20,
                  right: 20,
                  bottom: 10,
                ),
                onTap: () {
                  _funAddMoreItem(key: 'custom_document_images_field_post');
                },
                enable: _enableBasicInfo,
              ),
              const SizedBox(
                height: 20,
              ),
              if (_dataSOP["can_record_video"] != null)
                ...List.generate(_dataSOP["can_record_video"], (index) {
                  return VideoCaptureField(
                'Upload a Video of 30 Seconds',
                _data,
                    'video_${index + 1}', // Unique data key for each video
                _captureController,
                enable: _enableBasicInfo,
                  );
                }),
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

  void _funAddMoreItem({
    required String key,
  }) async {
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
        'other_image': true,
        'image_labels': _images.map((e) => e['type']).toList(),
      }).then((result) {
        _addMoreItemAdd(key, result);
      });
    } else if (location.isGranted && gps.isDisabled) {
      showDialog(
        context: context,
        builder: (builder) => PermissionDialog(
          'Permission',
          'GPS enable required',
          'Open setting',
          onActionPosition: _openGPS,
        ),
      );
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
        ),
      );
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

  _addMoreItemAdd(String key, response) async {
    if (response == null) return;
    _images.add({
      'section': key,
      'name': response['name'],
      'latitude': response['latitude'].toString(),
      'longitude': response['longitude'].toString(),
      'status': 'new',
      'type': response['title'],
      'box': response['box'],
    });
    _updateUi;

    await _uploadFile(_images.last);
  }

  _scrollListener(double value) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
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

  void _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    log('C61: Basic Info');
    _captureController.addUploadListener(_reUploadListener);
    _captureController.addOtherMediaListener(_otherMediaListener);
    widget._pagerController.addResponseListener(basicInfo, _onResponse);
    widget._pagerController.addButtonListener(0, _next);
    widget._pagerController.addScrollListener(basicInfo, _scrollListener);
    widget._pagerController.addIdListener(basicInfo, (id) => _data['id'] = id);
  }

  Future<void> _getSOPList({required int sopId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getSOPById(id: sopId);

    if (response == Api.defaultError || response == Api.internetError) {
      _loadDataApiResponse = Api.defaultError;
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      response.forEach((k, v) => _dataSOP[k] = v);
      _loadDataApiResponse = Api.success;
    }
  }

  _onResponse(response) async {
    log('C51: Response: $response');
    if (response == Api.defaultError) {
      _loadDataApiResponse = Api.defaultError;
      _updateUi;
      return;
    }

    response.forEach((k, v) => _data[k] = v);
    _loadDataApiResponse = Api.success;
    await _getSOPList(sopId: _data['sop_id'] ?? -1);
    await _getJobFiles(jobId: _data['id'] ?? -1);
    _editTextController.invalidate('remark');
    _updateUi;
  }

  Future<void> _getJobFiles({required int jobId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getJobFiles(id: jobId);

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      List<dynamic> imageList = [];
      imageList.addAll(_parseImages(
        data: response['vehichle_images_field_label'],
      ));
      imageList.addAll(_parseImages(
        data: response['document_image_field_label'],
      ));
      imageList.addAll(_parseImages(
        sectionKey: 'custom_vehichle_images_field_post',
        data: response['custom_vehichle_images_field_label'],
      ));
      imageList.addAll(_parseImages(
        sectionKey: 'custom_document_images_field_post',
        data: response['custom_document_image_field_label'],
      ));

      _data['images'] = [
        ...imageList,
        if (response['video_file'] != null &&
            (response['video_file'] as String).isNotEmpty)
          {
            'type': video,
            'name': response['video_file'],
            'status': Api.success,
          },
      ];
      _data['remark'] = response['job_remark'] ?? '';
    }
  }

  List<dynamic> _parseImages({
    String? sectionKey,
    required String? data,
  }) {
    if (data == null || data.isEmpty) return [];

    List<dynamic> images = [];
    try {
      List<dynamic> savedDocumentImages = json.decode(data);
      for (var e in savedDocumentImages) {
        Map<String, dynamic> imageMap = e as Map<String, dynamic>;
        String? imageLabel = imageMap['name'];
        String? imageUrl = imageMap['path'];
        if (!(imageUrl?.startsWith('http') ?? false) || imageLabel == null) {
          continue;
        }
        images.add({
          if (sectionKey != null) 'section': sectionKey,
          'type': imageLabel,
          'name': imageUrl,
          'latitude': 0.0,
          'longitude': 0.0,
          'time': DateTime.now().toString(),
          'updated': DateTime.now().toString(),
          'status': Api.success,
        });
      }
    } finally {}

    return images;
  }

  onJobSubmit(bool isOffline) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.basicInfo, isOffline);
    _localSaveJobBasicInfo;
    //    Navigator.of(context).pushReplacementNamed(Routes.homeScreen);

    widget._pagerController.navigate(1);
    ASnackBar.showSnackBar(
        scaffoldMessengerState,
        isOffline
            ? 'Entered data & photos saved locally.'
            : 'Entered data & photos saved on server.',
        0,
        status: Api.success);
  }

  _next() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);

    if (widget._pagerController.buttonLoading) return;

    if (!_enableBasicInfo) {
      widget._pagerController.navigate(1);
      return;
    }

    FocusScope.of(context).requestFocus(FocusNode());

    for (var v in _vehicleImagesFieldLabel) {
      if (_getMedia(v['form_field_label']).isEmpty) {
        ASnackBar.showWarning(scaffoldMessengerState,
            'You cannot submit this job as ${v['form_field_label']} is not clicked');
        return;
      }
    }

    for (var v in _documentImageFieldLabel) {
      if (_getMedia(v['form_document_label']).isEmpty) {
        ASnackBar.showWarning(scaffoldMessengerState,
            'You cannot submit this job as ${v['form_document_label']} is not clicked');
        return;
      }
    }

    if (_getData('remark').isEmpty) {
      ASnackBar.showWarning(scaffoldMessengerState,
          'You cannot submit this job as the remark is not entered');
    } else {
      widget._pagerController.setButtonProgress(true);

      if (await Api.networkAvailable() &&
          _getData('is_offline') == 'no' &&
          _imageLocationInvalid() &&
          context.mounted) {
        showDialog(
            context: context, builder: (builder) => const LocationWarning());
        widget._pagerController.setButtonProgress(false);
        return;
      }
      // Setup job data
      setupJobData(
        context: context,
        scaffoldMessengerState: scaffoldMessengerState,
        navigatorState: Navigator.of(context),
        images: _images,
        locationControllerPosition:
            _data['location'], // Replace with the actual location data
        data: _data,
        dataSOP: _dataSOP,
        customVehicleImagesField:
            _customVehicleImagesField, // Ensure you have this defined
        customDocumentImageField:
            _customDocumentImageField, // Ensure you have this defined
        retryFailedFile: _retryFailedFile, // Replace with your actual function
        onJobSubmit: onJobSubmit,
        getData: _getData,
      );

      if (_data['id'].isNegative) {
        await widget._pagerController.createJob();
        widget._pagerController
            .navigate(1); // Navigate to the next screen after job creation
      } else {
        widget._pagerController
            .navigate(1); // Navigate to the next screen if job already exists
      }
    }
  }

  setupJobData({
    required BuildContext context,
    required ScaffoldMessengerState scaffoldMessengerState,
    required NavigatorState navigatorState,
    required List<dynamic> images,
    required dynamic locationControllerPosition,
    required Map<dynamic, dynamic> data,
    required Map<dynamic, dynamic> dataSOP,
    required List<dynamic> customVehicleImagesField,
    required List<dynamic> customDocumentImageField,
    required Function retryFailedFile,
    required Function onJobSubmit,
    required Function getData,
  }) {
    JobDataStorage().setData(
      context: context,
      scaffoldMessengerState: scaffoldMessengerState,
      navigatorState: navigatorState,
      images: images,
      locationControllerPosition: locationControllerPosition,
      data: data,
      dataSOP: dataSOP,
      customVehicleImagesField: customVehicleImagesField,
      customDocumentImageField: customDocumentImageField,
      retryFailedFile: retryFailedFile,
      onJobSubmit: onJobSubmit,
      getData: getData,
    );
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

  Future<bool> _uploadFile(Map item) async {
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
              'forcePortrait': false,
            },
          ),
        );
      }
    } catch (e) {
      log("When Adding Failed to get path $e");

      item['status'] = Api.internetError;
      _captureController.invalidate(item['type'], item);
      return false;
    }

    File imageFile = File(item['name']);
    String response = await Api(scaffoldMessengerState).uploadMSFile(
      file: imageFile,
    );

    if (response.startsWith('http')) {
      await File(item['name']).delete();
      item['name'] = response;
      item['status'] = Api.success;
    } else {
      item['status'] = response;
    }

    _captureController.invalidate(item['type'], item);
    return true;
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

  get _updateUi {
    if (mounted) setState(() {});
  }

  get _enableBasicInfo =>
      _data['job_status'] == pending || _data['job_status'] == rejected;

  List get _images => _data['images'];

  get _localSaveJobBasicInfo => LocalJobsDetail.updateJobBasicInfo(
      _data['id'], {'images': _images, 'remark': _getData('remark')});
}
