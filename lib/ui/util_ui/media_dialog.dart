import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

class MediaDialog extends StatefulWidget {
  final String path;
  final bool picture;
  final String? timestamp; // Added timestamp parameter
  final String? location; // Added location parameter
  final String? mediaType; // Added mediaType parameter

  const MediaDialog(
    this.path, {
    Key? key, 
    this.picture = true,
    this.timestamp, // Added timestamp parameter
    this.location, // Added location parameter
    this.mediaType, // Added mediaType parameter
  }) : super(key: key);

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
          // Main content - Image or Video at their natural size
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: widget.picture ? _imageWithOverlay : _videoFile,
          ),
          // Close button in top right
          Container(
            decoration: const BoxDecoration(
              color: Colors.red, 
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(180)),
            ),
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

  // Format timestamp for display
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp; // Return original string if parsing fails
    }
  }

  // Image with timestamp and location overlay
  Widget get _imageWithOverlay {
    // Check if this is a document by examining type rather than extension
    bool isDocument = false;
    
    // If the media has a type property that indicates it's a document
    if (widget.mediaType != null && 
        (widget.mediaType == 'document' || widget.mediaType?.toLowerCase().contains('document') == true)) {
      isDocument = true;
    }
    
    return Stack(
      children: [
        // The image at its natural size
        _networkMedia
          ? Image.network(widget.path, loadingBuilder: _loadingBuilder, errorBuilder: _errorBuilder)
          : Image.file(File(widget.path)),
        
        // Timestamp and location overlay - only shown for images, not documents
        if (widget.picture && !isDocument && (widget.timestamp != null || widget.location != null))
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.timestamp != null)
                    Text(
                      _formatTimestamp(widget.timestamp!),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.location != null && widget.location!.isNotEmpty)
                    Text(
                      widget.location!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? event) {
    if (event == null) {
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
    if (widget.picture) return;

    _playerController = _networkMedia
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path))
      ..addListener(_funVideoListener);
    await _playerController?.initialize();
    _updateUi;
  }

  _funVideoListener() {
    if (_playerController!.value.duration.inMilliseconds == _playerController!.value.position.inMilliseconds) {
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
