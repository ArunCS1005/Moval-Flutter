import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaDialog extends StatefulWidget {

  final String path;
  final bool picture;

  const MediaDialog(this.path, {Key? key, this.picture = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }

}

class _State extends State<MediaDialog> {

  VideoPlayerController? _playerController;

  @override
  void initState() {
    _funVideoInit();
    super.initState();
  }


  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.white12)),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          widget.picture ? _imageFile : _videoFile,
          Container(
            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(180),),),
            child: IconButton(
              iconSize: 20,
              onPressed: _funOnCloseBtn,
              alignment: Alignment.topRight,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  get _imageFile =>
      _networkMedia
      ? Image.network(widget.path, loadingBuilder: _loadingBuilder, errorBuilder: _errorBuilder,)
      : Image.file(File(widget.path));


  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? event) {

    if(event == null) {
      return child;
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Loading image...',
            style: TextStyle(fontSize: 18,),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _errorBuilder(BuildContext context, Object object, StackTrace? trace) {
    return const Center(
      child: Center(
        child: Text(
          'Image\nLoad Failed',
          style: TextStyle(fontSize: 18,),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  get _videoFile => Stack(
    alignment: Alignment.bottomCenter,
    children: [
      AspectRatio(
        aspectRatio: _playerController?.value.aspectRatio ?? 3.5,
        child: _playerController == null || !(_playerController?.value.isInitialized ?? false)
            ? _videoLoader
            : VideoPlayer(_playerController!),
      ),
      if (_playerController?.value.isInitialized ?? false)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(180)),
          child: IconButton(
            iconSize: 20,
            onPressed: _funVideoController,
            icon: Icon(_playerController!.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow),
          ),
        ),
    ],
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


  _funVideoInit() async {

    if(widget.picture) return;

    _playerController = _networkMedia
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path))
      ..addListener(_funVideoListener);
    await _playerController?.initialize();
    _updateUi;

  }


  _funVideoListener() {

    if(_playerController!.value.duration.inMilliseconds == _playerController!.value.position.inMilliseconds) {
      _updateUi;
    }

  }


  _funVideoController () {

    if (_playerController!.value.isPlaying) {
      _playerController?.pause();
    } else {
      _playerController?.play();
    }

    _updateUi;
  }


  _funOnCloseBtn() {
    Navigator.pop(context);
  }

  get _updateUi => setState((){});

  get _networkMedia => widget.path.startsWith('http');

}
