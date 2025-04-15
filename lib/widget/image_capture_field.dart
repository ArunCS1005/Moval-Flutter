import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moval/api/api.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/ui/util_ui/media_dialog.dart';
import 'package:moval/ui/util_ui/permission_dialog.dart';
import 'package:moval/util/capture_controller.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImageCaptureField extends StatefulWidget {
  final String title;
  final Map data;
  final String dataKey;
  final bool isAIEnabled;
  final bool addDate;
  
  final CaptureController controller;
  final void Function(dynamic)? onMediaSaved;
  final void Function(dynamic)? onMediaRemoved;

  const ImageCaptureField(
    this.title,
    this.data,
    this.dataKey,
    this.controller, {
    Key? key,
    this.onMediaSaved,
    this.isAIEnabled = false,
    this.addDate = true,
    
    this.onMediaRemoved,

  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<ImageCaptureField> {
  VideoPlayerController? _playerController;
  late Box _box;
  late String _uniqueCacheKey;

  @override
  void initState() {
    super.initState();
    _initHive();
    _funUpdateData();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox('mediaCache');
    _uniqueCacheKey = '${widget.data['id']}_${widget.dataKey}';
    _loadCachedMedia();
  }

  void _loadCachedMedia() {
    final cachedMedia = _box.get(_uniqueCacheKey);
    if (cachedMedia != null) {
      setState(() {
        widget.data['images'] = cachedMedia;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(widget.dataKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: _funOnClick,
        child: Container(
          decoration: const BoxDecoration(
              boxShadow: [BoxShadow(blurRadius: 1, color: Colors.black38)],
              color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AText(widget.title)),
              _media,
            ],
          ),
        ),
      ),
    );
  }

  get _media => _funGetMedia().isEmpty
      ? _isPicture
          ? SvgPicture.asset('assets/images/camera-icon.svg')
          : const Icon(Icons.video_camera_back)
      : Stack(
          alignment: Alignment.topRight,
          children: [
            _isPicture
                ? _imageView
                : SizedBox(width: 75, child: VideoPlayer(_playerController!)),
            if (_enableBasicInfo)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(180))),
                child: IconButton(
                  iconSize: 12,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topRight,
                  onPressed: _funRemoveMedia,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            if (_enableBasicInfo) _status(),
          ],
        );

  get _imageView => _networkMedia
      ? Image.network(
          _funGetMedia(),
          fit: BoxFit.cover,
          width: 75,
          loadingBuilder: _loadingBuilder,
          errorBuilder: _errorBuilder,
        )
      : Image.file(
          File(_funGetMedia()),
          fit: BoxFit.cover,
          width: 75,
          errorBuilder: _errorBuilder,
        );

  Widget _loadingBuilder(
      BuildContext context, Widget child, ImageChunkEvent? event) {
    if (event == null) {
      return child;
    }

    return Container(
      width: 75,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1,
        ),
      ),
    );
  }

  Widget _errorBuilder(BuildContext context, Object object, StackTrace? trace) {
    return const SizedBox(
      width: 75,
      child: Center(
        child: Text(
          'Image\nLoad Failed',
          style: TextStyle(
            fontSize: 8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  _status() {
    switch (_funGetStatus()) {
      case Api.success:
        return _success;
      case Api.defaultError:
      case Api.internetError:
        return _failed;
      case Api.loading:
        return _loader;
      default:
        return Container();
    }
  }

  get _success => Container(
        width: 75,
        margin: const EdgeInsets.only(bottom: 2, right: 2),
        alignment: Alignment.bottomRight,
        child: const Icon(
          Icons.done_all,
          size: 15,
          color: Colors.green,
        ),
      );

  get _failed => Container(
        width: 75,
        alignment: Alignment.center,
        child: InkWell(
          onTap: _funReUploadMedia,
          child: const Icon(
            Icons.file_upload,
            size: 25,
            color: Color.fromARGB(100, 255, 0, 0),
          ),
        ),
      );

  get _loader => Container(
        width: 75,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
            backgroundColor: Colors.blue,
          ),
        ),
      );

  _funOnClick() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (_funGetMedia().isEmpty) {
      if (_isPicture) {
        _checkCameraPermission();
      } else {
        _checkVideoPermission();
      }
    } else {
      // Get timestamp and location data for the selected image
      String? timestamp;
      String? location;
      
      // Find the image data in the list
      for (var item in _images) {
        if (item['type'] == widget.dataKey) {
          timestamp = item['time']?.toString();
          
          // Create location string from latitude and longitude if available
          if (item['latitude'] != null && item['longitude'] != null) {
            String locationDetail = "";
            if (item.containsKey('location') && item['location'] != null) {
              // Use pre-formatted location if available
              locationDetail = item['location'];
            } else {
              // Otherwise just show coordinates
              final String lat = item['latitude'].toString();
              final String lng = item['longitude'].toString();
              if (lat != '0.0' && lng != '0.0') {
                locationDetail = "$lat, $lng";
              }
            }
            
            if (locationDetail.isNotEmpty) {
              location = locationDetail;
            }
          }
          break;
        }
      }
      
      // Determine if this is a document type based on dataKey
      bool isDocument = widget.dataKey.toLowerCase().contains('document') || 
                        widget.title.toLowerCase().contains('document');
      
      showDialog(
        context: context,
        builder: (builder) => MediaDialog(
          _funGetMedia(),
          picture: _isPicture,
          timestamp: timestamp,
          location: location,
          mediaType: isDocument ? 'document' : 'vehicle',
        ),
      );
    }
  }

  _checkCameraPermission() async {
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
      Navigator.pushNamed(context, Routes.captureImage, arguments: {
        'title': widget.title,
        'is_ai_enabled': widget.isAIEnabled,
        'addDate': widget.addDate,
        
      }).then(_onResult);
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
        ),
      );
    }
  }

  _checkVideoPermission() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    var camera = await Permission.camera.status;
    var microphone = await Permission.microphone.status;

    if (camera.isGranted && microphone.isGranted) {
      Navigator.pushNamed(context, Routes.captureVideo, arguments: widget.title)
          .then(_onResult);
    } else if (await Permission.camera.shouldShowRequestRationale) {
      await Permission.camera.request();
    } else if (await Permission.microphone.shouldShowRequestRationale) {
      await Permission.microphone.request();
    } else {
      showDialog(
        context: context,
        builder: (builder) => PermissionDialog(
          'Permission',
          'Camera and microphone permission required',
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

  _onResult(_) async {
    if (_ == null) return;

    await _funAddMedia(_);
    _playerController =
        _isPicture ? null : VideoPlayerController.file(File(_funGetMedia()));
    await _playerController?.initialize();
    _updateUi;
  }

  _funRemoveMedia() {
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        if (!_networkMedia) File(_funGetMedia()).delete();
        item['name'] = '';
        item['status'] = '';
        item['latitude'] = '';
        item['longitude'] = '';
        _box.delete(_uniqueCacheKey); // Remove from cache
        if (widget.onMediaRemoved != null) widget.onMediaRemoved!(item);
        _updateUi;
        break;
      }
    }
  }

  _funReUploadMedia() {
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        item['status'] = 'retry';
        widget.controller.invalidateUpload(widget.dataKey);
        break;
      }
    }
  }

  _funUpdateData() {
    widget.controller.addListener(widget.dataKey, () => _updateUi);

    bool available = false;

    if (_images.isEmpty) {
      _images.add({
        'type': widget.dataKey,
        'name': '',
      });
    } else {
      for (var item in _images) {
        if (available = item['type'] == widget.dataKey) break;
      }

      if (!available) {
        _images.add({
          'type': widget.dataKey,
          'name': '',
        });
      }
    }
  }

  _funAddMedia(Map result) async {
    // Check if this is a document type
    bool isDocumentType = widget.dataKey.toLowerCase().contains('document') || 
                        widget.title.toLowerCase().contains('document');
    
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        item['name'] = result['name'];
        
        // For document images, set location and time data to null
        if (isDocumentType) {
          item['latitude'] = null;
          item['longitude'] = null;
          item['time'] = null;
          item['updated'] = null;
        } else {
          // For vehicle images, use the provided data
          item['latitude'] = result['latitude'].toString();
          item['longitude'] = result['longitude'].toString();
          item['time'] = result['time'];
          item['updated'] = result['updated'].toString();
        }
        
        item['status'] = 'new';
        item['ai_box'] = result['ai_box'];
        item['final_box'] = result['final_box'];
        _box.put(_uniqueCacheKey, _images); // Save to cache
        if (widget.onMediaSaved != null) widget.onMediaSaved!(item);
        break;
      }
    }
  }

  String _funGetMedia() {
    for (var item in _images) {
      if (item['type'] == widget.dataKey) return item['name'] ?? '';
    }
    return '';
  }

  String _funGetStatus() {
    if (_networkMedia) return Api.success;
    for (var item in _images) {
      if (item['type'] == widget.dataKey) return item['status'] ?? '';
    }
    return '';
  }

  get _updateUi => setState(() {});

  get _images => widget.data['images'];

  get _isPicture => widget.dataKey != video;

  get _networkMedia => _funGetMedia().startsWith('http');

  get _enableBasicInfo =>
      widget.data['job_status'] == pending ||
      widget.data['job_status'] == rejected;
}
