import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:moval/widget/header.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class CaptureVideo extends StatefulWidget {

  const CaptureVideo({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }

}

class _State extends State<CaptureVideo> with TickerProviderStateMixin, WidgetsBindingObserver {

  CameraController?      _controller;
  VideoPlayerController? _playerController;
  AnimationController?   _animController;
  int                    _videoState = -2;
  String                 _title = '';
  String                 _filePath = '';
  bool                   _flashOn = false;
  double                 _minAvailableZoom = 1.0;
  double                 _maxAvailableZoom = 1.0;
  double                 _currentScale     = 1.0;
  double                 _baseScale        = 1.0;
  int                    _pointers         = 0;

  final int              _videoDuration  = 31;


  _funGetArguments() async {

    await Future.delayed(Duration.zero);

    _title = ModalRoute.of(context)?.settings.arguments as String;

  }


  _funInitCamera() async {

    await Future.delayed(const Duration(milliseconds: 100));

    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller?.initialize();
    await _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);

    _minAvailableZoom = await _controller?.getMinZoomLevel() ?? 1.0;
    _maxAvailableZoom = await _controller?.getMaxZoomLevel() ?? 1.0;

    _filePath = '';
    _videoState = -1;
    _animController?.value = 0;
    _playerController?.dispose();

    _funUpdateUi();
  }


  _funRecaptureVideo() {

    if (_filePath.isNotEmpty) {
      File(_filePath).delete();
    }

    if(_controller == null) {
      _funInitCamera();
    } else {
      _filePath = '';
      _videoState = -1;
      _animController?.value = 0;
      _playerController?.dispose();
      _funUpdateUi();
    }
  }


  _funVideoSave() async {

    if(_filePath.isEmpty) {

      log("Capture Image > Not validate title={$_title} or image={$_filePath}");

      return;
    }

    final parentDir = await getApplicationDocumentsDirectory();

    final file = await File(_filePath).copy("${parentDir.parent.path}/files/${path.basename(_filePath)}");
    File(_filePath).delete();

    Navigator.pop(context, file.path);

  }


  _funChangeFlash() async {

    if(_flashOn){

      await _controller?.setFlashMode(FlashMode.off);
    _flashOn = false;

    } else {

    await _controller?.setFlashMode(FlashMode.torch);
    _flashOn = true;

    }

    _funUpdateUi();

  }


  _funCaptureVideo() async {

    if(_videoState == 0) return;
    _videoState = 0;

    await _controller?.startVideoRecording();
    _animController?.forward(from: 0);

  }


  _funVideoComplete() async {

    final xFile = await _controller?.stopVideoRecording();

    _filePath = xFile!.path;

    _playerController = VideoPlayerController.file(File(_filePath));
    await _playerController?.initialize();
    _playerController?.addListener(_funPlayerListener);

    _videoState = 1;

    _funUpdateUi();

  }


  _funAnimListener() {

    if(_animController?.value == 1){
      _funVideoComplete();
      return;
    }

    _funUpdateUi();
  }


  _funPlayerListener() {

    if(_playerController!.value.position.inMilliseconds
        == _playerController!.value.duration.inMilliseconds) {
      _funUpdateUi();
    }

  }


  _funPlayPause() async {

    if(_playerController == null) {
      return;
    }

    if (_playerController!.value.isPlaying) {
      _playerController?.pause();
    } else {
      _playerController?.play();
    }

    _funUpdateUi();

  }


  String _funCalculateTime() {
    final seconds = (_animController!.value * _videoDuration).toInt();
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      return '${seconds ~/ 60}m ${seconds % 60}s';
    }
  }


  _funUpdateUi() {
    setState(() {});
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if(state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if(state == AppLifecycleState.resumed && _controller == null) {
      _funInitCamera();
    }

  }

  @override
  void initState() {

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _videoDuration),
    )..addListener(_funAnimListener);

    _funGetArguments();
    _funInitCamera();

    super.initState();
  }


  @override
  void dispose() {
    _controller?.dispose();
    _animController?.dispose();
    _playerController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Header(_title, child: _getChild(),);
  }


  _getChild() {

    if (_videoState == -2) {
      return _loader;
    } else if (_videoState == -1 || _videoState == 0) {
      return _cameraPreview;
    } else if (_videoState == 1) {
      return _mediaPreview;
    } else {
      return Container();
    }

  }

  get _loader => Container(
    alignment: Alignment.center,
    child: const SizedBox(
      width: 35,
      height: 35,
      child: CircularProgressIndicator(),
    ),
  );

  get _cameraPreview => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Listener(
                    onPointerDown: (_) => _pointers++,
                    onPointerUp: (_) => _pointers--,
                    child: CameraPreview(
                      _controller!,
                      child: LayoutBuilder(builder: (context, constraints){
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _scaleStart,
                          onScaleUpdate: _scaleUpdate,
                          onTapDown: (details) => _onFocusRequest(details, constraints),
                        );
                      }),
                    ),
                  ),
                ),
                if (_animController != null)
                  LinearProgressIndicator(
                    value: _animController!.value,
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _captureBtn(),
                _flashBtn(),
              ],
            ),
          ),
        ],
      );

  get _mediaPreview => Column(
    mainAxisSize: MainAxisSize.max,
    children: [
      Expanded(
        child: Container(
          alignment: Alignment.center,
          child: _playerController == null ? Container() : VideoPlayer(_playerController!),
        ),
      ),
      SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _captureBtn(),
            _playBtn(),
            _flashBtn(),
          ],
        ),
      ),
    ],
  );

  _captureBtn() {
    if(_videoState == -1) {
      return IconButton(onPressed: _funCaptureVideo, icon: const Icon(Icons.video_camera_back));
    } else if(_videoState == 0) {
      return Text(_funCalculateTime());
    } else if(_videoState == 1) {
      return IconButton(onPressed: _funVideoSave, icon: const Icon(Icons.done));
    } else{
      return Container();
    }
  }

  _flashBtn() {
    if (_videoState == -1 || _videoState == 0 && false) {
      return IconButton(
        onPressed: _funChangeFlash,
        icon: Icon(_flashOn ? Icons.flashlight_on : Icons.flashlight_off),
      );
    } else if (_videoState == 1) {
      return IconButton(
        onPressed: _funRecaptureVideo,
        icon: const Icon(Icons.close),
      );
    } else {
      return Container();
    }
  }

  _playBtn() {

    if (_videoState == 1) {
      return IconButton(onPressed: _funPlayPause, icon: Icon(
          _playerController?.value.isPlaying ?? false
              ? Icons.pause
              : Icons.play_arrow),);
    } else {
      return Container();
    }

  }



  _scaleStart(ScaleStartDetails details) async {
    _baseScale = _currentScale;
  }

  _scaleUpdate(ScaleUpdateDetails details) {

    if(_controller == null || _pointers != 2) return;

    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);

    _controller?.setZoomLevel(_currentScale);

  }

  _onFocusRequest(TapDownDetails details, BoxConstraints constraints){

    if(_controller == null) return;

    final offset = Offset(
        details.localPosition.dx / constraints.maxWidth,
        details.localPosition.dy / constraints.maxHeight);

    _controller?.setExposurePoint(offset);
    _controller?.setFocusPoint(offset);

  }


}
