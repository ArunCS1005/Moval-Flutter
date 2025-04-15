import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:moval/api/api.dart';
import 'package:moval/ui/util_ui/media_dialog.dart';
import 'package:moval/ui/util_ui/permission_dialog.dart';
import 'package:moval/util/capture_controller.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VideoCaptureField extends StatefulWidget {
  final String title;
  final Map data;
  final String dataKey;
  final CaptureController controller;
  final bool enable;

  const VideoCaptureField(this.title, this.data, this.dataKey, this.controller,
      {Key? key, this.enable = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<VideoCaptureField> {
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

  void _loadCachedMedia() async {
    final cachedMedia = _box.get(_uniqueCacheKey);
    if (cachedMedia != null) {
      setState(() {
        widget.data['images'] = cachedMedia;
      });
      if (_funGetMedia().isNotEmpty) {
        _playerController = _funGetMedia().startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(_funGetMedia()))
            : VideoPlayerController.file(File(_funGetMedia()));
        await _playerController?.initialize();
        _updateUi;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(widget.dataKey);
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_funGetMedia().isNotEmpty) _videoContainer,
          Button('Upload a Video of 30 Seconds',
              enable: widget.enable && _funGetMedia().isEmpty,
              onTap: _captureVideo),
        ],
      ),
    );
  }

  get _videoContainer => AspectRatio(
        aspectRatio: 2.5,
        child: Container(
          clipBehavior: Clip.hardEdge, // Add clip behavior to prevent overflow
          decoration: BoxDecoration(
            color: Colors.black, // Keep only this color definition
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: InkWell(
                  onTap: _funMediaDialog,
                  child: Container(
                    width: double.infinity, 
                    height: double.infinity, 
                    child: _playerController == null ||
                            !(_playerController?.value.isInitialized ?? false)
                        ? _videoLoader
                        : FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _playerController!.value.size.width,
                            height: _playerController!.value.size.height,
                            child: VideoPlayer(_playerController!),
                          ),
                        ),
                  ),
                ),
              ),
              if (_enableBasicInfo)
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(180),
                    ),
                  ),
                  child: IconButton(
                    iconSize: 15,
                    alignment: Alignment.topRight,
                    onPressed: _funRemoveMedia,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              if (_enableBasicInfo) _status(),
            ],
          ),
        ),
      );

  get _videoLoader => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
              backgroundColor: Colors.blue,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Video Loading',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );

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
          color: Colors.greenAccent,
        ),
      );

  get _failed => Container(
        alignment: Alignment.center,
        child: InkWell(
          onTap: _funReUploadMedia,
          child: const Icon(
            Icons.file_upload,
            size: 30,
            color: Colors.redAccent,
          ),
        ),
      );

  get _loader => Container(
        alignment: Alignment.center,
        child: const SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
            backgroundColor: Colors.blue,
          ),
        ),
      );

  _captureVideo() async {
    NavigatorState navigatorState = Navigator.of(context);

    FocusScope.of(context).requestFocus(FocusNode());

    await Permission.camera.request();
    await Permission.microphone.request();

    var camera = await Permission.camera.status;
    var microphone = await Permission.microphone.status;

    if (camera.isGranted && microphone.isGranted) {
      navigatorState
          .pushNamed(Routes.captureVideo, arguments: widget.title)
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
              ));
    }
  }

  _openAppSetting() async {
    Navigator.pop(context);
    AppSettings.openAppSettings();
  }

  _onResult(_) async {
    if (_ == null) return;

    await _funAddMedia(_);
    _playerController = VideoPlayerController.file(File(_));
    await _playerController?.initialize();
    _updateUi;
  }

  _funMediaDialog() {
    // Get timestamp for the video if available
    String? timestamp;
    
    // Find the video data in the list
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        timestamp = item['time']?.toString();
        break;
      }
    }
    
    showDialog(
        context: context,
        builder: (builder) => MediaDialog(
              _funGetMedia(),
              picture: false,
              timestamp: timestamp,
              mediaType: "video",  // Adding mediaType as "video"
            ));
  }

  _funRemoveMedia() {
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        item['name'] = '';
        item['status'] = 'empty';
        _playerController?.dispose();
        _box.delete(_uniqueCacheKey); // Remove from cache
        _updateUi;
        break;
      }
    }
  }

  _funUpdateData() async {
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

    if (_funGetMedia().isNotEmpty) {
      _playerController = _funGetMedia().startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(_funGetMedia()))
          : VideoPlayerController.file(File(_funGetMedia()));

      await _playerController?.initialize();
      _updateUi;
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

  _funAddMedia(String name) async {
    for (var item in _images) {
      if (item['type'] == widget.dataKey) {
        item['name'] = name;
        item['status'] = 'new';
        await _box.put(_uniqueCacheKey, _images); // Save to cache
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

  get _updateUi {
    if (mounted) setState(() {});
  }

  List get _images => widget.data['images'];

  get _networkMedia => _funGetMedia().startsWith('http');

  get _enableBasicInfo =>
      widget.data['job_status'] == 'pending' ||
      widget.data['job_status'] == 'rejected';
}
