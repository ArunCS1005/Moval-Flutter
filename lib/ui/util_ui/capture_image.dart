import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moval/util/location_controller.dart';
import 'package:moval/widget/header.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../api/api.dart';
import '../../widget/a_snackbar.dart';
import '../../widget/a_text.dart';
import '../../widget/edit_text.dart';

class CaptureImage extends StatefulWidget {
  const CaptureImage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<CaptureImage> with WidgetsBindingObserver {

  final Map _data = {};
  CameraController? _controller;
  bool _flashOn = false;
  int _pictureMode = -2;
  String _title = '';
  String _filePath = '';
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  int _pointers = 0;
  double _latitude = 0;
  double _longitude = 0;
  String _time = '';
  bool _imageEditSuccess = true;
  bool _isOtherImage = false;
  List _imageLabels = [];
  bool _isAIEnabled = false;
  final List<Box> _boxes = [];
  List<Box> _ogBoxes = [];
  Size? _aiImageSize;
  ScreenshotController screenshotController = ScreenshotController();

  static const MethodChannel _channel = MethodChannel("423u5.imageEdit");

  _funAddLocationToImage() async {
    try {
      _latitude = LocationController.position?.latitude ?? 0.0;
      _longitude = LocationController.position?.longitude ?? 0.0;

      log("Latitude $_latitude Longitude $_longitude");

      final placeMark = await placemarkFromCoordinates(_latitude, _longitude);

      String place = '${placeMark.first.subLocality}, ${placeMark.first.locality}';
      //String _place = '$_latitude, $_longitude';

      final result = await _channel.invokeMethod(
        "edit",
        jsonEncode(
          {
            'path': _filePath,
                'location': addDate ? "$_time\n$place" : place,
            'forcePortrait' : !(_title == 'Chassis number' || _title == 'Odometer')
          },
        ),
      ) ?? false;

      _imageEditSuccess = result;

      log("Image add text result $_imageEditSuccess");
    } catch(e){
      log("Error when editing image $e");
      _imageEditSuccess = false;
    }
  }


  _funDoneImage() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    if (_filePath.isEmpty) {
      log("Capture Image > Not validate title={$_title} or image={$_filePath}");
      return;
    }

    final parentDir = await getApplicationDocumentsDirectory();

    File file = await File(_filePath)
        .copy("${parentDir.parent.path}/files/${path.basename(_filePath)}");

    if(_pictureMode == 2) {
      Uint8List? image = await screenshotController.capture(
          delay: const Duration(milliseconds: 10));
      if (image == null) {
        ASnackBar.showSnackBar(
          scaffoldMessengerState,
          "AI Image not captured",
          0,
        );
        return;
      }

      File file = await File(
              '${parentDir.parent.path}/files/${path.basename(_filePath)}')
          .create(recursive: true);
      file.writeAsBytesSync(image);
    }

    File(_filePath).delete();
    navigatorState.pop({
      'name': file.path,
      'latitude': _latitude,
      'longitude': _longitude,
      'time': _time,
      'updated': _imageEditSuccess ? 1 : 0,
      'title': _getData('title'),
      'ai_box': jsonEncode(_ogBoxes
          .map((e) => {
                'x1': e.imageRect.left,
                'y1': e.imageRect.top,
                'x2': e.imageRect.right,
                'y2': e.imageRect.bottom,
              })
          .toList()),
      'final_box': jsonEncode(_boxes
          .map((e) => {
                'x1': e.imageRect.left,
                'y1': e.imageRect.top,
                'x2': e.imageRect.right,
                'y2': e.imageRect.bottom,
              })
          .toList()),
    });
  }

  Future<File?> _getImageFileFromUrl(String url) async {
    final http.Response responseData = await http.get(Uri.parse(url));
    Uint8List uInt8list = responseData.bodyBytes;
    var buffer = uInt8list.buffer;
    ByteData byteData = ByteData.view(buffer);
    var tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/img').writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  _funAIImage(ScaffoldMessengerState scaffoldMessengerState) async {
    _pictureMode = -3;
    _funUpdateUi();

    String response = await Api(scaffoldMessengerState).uploadMSFile(
      file: File(_filePath),
    );

    if (!response.startsWith('http')) {
      ASnackBar.showSnackBar(
        scaffoldMessengerState,
        "Image not uploaded",
        0,
      );
      return;
    }

    String imageUrl = response;
    File? imageFile = await _getImageFileFromUrl(imageUrl);
    if (imageFile == null) return;
    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    _aiImageSize =
        Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

    dynamic responseAI = await Api(scaffoldMessengerState).predictAccidentAI(
      imageUrl: imageUrl,
    );

    _ogBoxes = (responseAI is! List)
        ? []
        : responseAI.map((e) {
            final bBox = e['bbox'];
            return Box(
              imageRect: Rect.fromPoints(
                  Offset(bBox[0], bBox[1]), Offset(bBox[2], bBox[3])),
              color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(1.0),
            );
          }).toList();

    _boxes.addAll(_ogBoxes);

    if (_boxes.isEmpty) {
      ASnackBar.showSnackBar(
        scaffoldMessengerState,
        "No accident section found",
        0,
      );
    }

    ASnackBar.showSnackBar(
      scaffoldMessengerState,
      "Tap on a box to select. Drag from center of selected box to move the box. Drag from side of selected box to resize",
      0,
      duration: const Duration(seconds: 5),
    );

    _pictureMode = 2;
    _funUpdateUi();
  }

  _funCaptureImage() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    if (_pictureMode != -1) return;

    if (_isOtherImage) {
      String title = _getData('title');

      if (title.isEmpty) {
        ASnackBar.showWarning(scaffoldMessengerState,
            'You cannot submit this image as the title is not entered');
        return;
      }

      if (_imageLabels.any((e) =>
          e.toString().trim().toLowerCase() == title.trim().toLowerCase())) {
        ASnackBar.showWarning(scaffoldMessengerState,
            'You cannot submit this title as this sop label already exists');
        return;
      }
    }

    _pictureMode = 0;
    _funUpdateUi();

    final xFile = await _controller?.takePicture();
    _filePath = xFile?.path ?? '';
    _time = DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
   
    await _funAddLocationToImage();
   

    _pictureMode = 1;
    await _controller?.setFlashMode(FlashMode.off);
    _funUpdateUi();
  }


  _funRecaptureImage() async {
    _pictureMode = -1;
    await _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    File(_filePath).delete();

    _funUpdateUi();
  }

  _funChangeFlash() async {
    if (_flashOn) {
      await _controller?.setFlashMode(FlashMode.off);
      _flashOn = false;
    } else {
      await _controller?.setFlashMode(FlashMode.torch);
      _flashOn = true;
    }

    _funUpdateUi();
  }

  _funAddBox() async {
    _boxes.add(Box(
      imageRect: Rect.fromPoints(const Offset(0, 0), const Offset(400, 400)),
      color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(1.0),
    ));
    _funUpdateUi();
  }

  _funRemoveBox() async {
    int selectedBoxIndex = getSelectedBoxIndex();
    if (selectedBoxIndex < 0 || selectedBoxIndex >= _boxes.length) return;
    _boxes.removeAt(selectedBoxIndex);
    _funUpdateUi();
  }

  bool addDate = true;
  _funGetArguments() async {
    ModalRoute? modalRoute = ModalRoute.of(context);

    await Future.delayed(Duration.zero);

    Map<String, dynamic> data =
        (modalRoute?.settings.arguments as Map<String, dynamic>?) ?? {};
    _title = data['title'];
    _isAIEnabled = data['is_ai_enabled'] ?? false;
    addDate = data['addDate'] ?? true;
    
    _isOtherImage = data['other_image'] ?? false;
    _imageLabels = data['image_labels'] ?? [];
  }


  _funInitCamera() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    await _controller?.initialize();
    await _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);

    _minAvailableZoom = await _controller?.getMinZoomLevel() ?? 1.0;
    _maxAvailableZoom = await _controller?.getMaxZoomLevel() ?? 1.0;

    _pictureMode = -1;
    _filePath    = '';

    _funUpdateUi();
  }


  _funUpdateUi(){
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
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _funGetArguments();
      _funInitCamera();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    String dataTitle = _getData('title');
    return Header(
      dataTitle.isEmpty ? _title : dataTitle,
      child: _getChild(context),
    );
  }


  Widget _getChild(BuildContext context) {
    if (_pictureMode == -3) {
      return _loaderAIWait;
    } else if (_pictureMode == -2) {
      return _loader;
    } else if (_pictureMode == -1 || _pictureMode == 0) {
      return _cameraPreview;
    } else if (_pictureMode == 1) {
      return _mediaPreview(context);
    } else if (_pictureMode == 2) {
      return _mediaPreviewWithAI(context);
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

  get _loaderAIWait => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AText(
            'Please wait while the Moval AI Model is processing the clicked Vehicle Image for damages detection',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          SizedBox(
            width: 35,
            height: 35,
            child: CircularProgressIndicator(),
          ),
        ],
      );

  get _cameraPreview => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Listener(
                onPointerDown: (_) => _pointers++,
                onPointerUp: (_) => _pointers--,
                child: CameraPreview(
                  _controller!,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _scaleStart,
                      onScaleUpdate: _scaleUpdate,
                      onTapDown: (details) =>
                          _onFocusRequest(details, constraints),
                    );
                  }),
                ),
              ),
            ),
          ),
          SizedBox(
            height: (_isOtherImage) ? 120 : 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isOtherImage)
                  EditText(
                    "Enter title",
                    'title',
                    _data,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    isEnable: (_pictureMode == -1),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _captureBtn(),
                    _flashBtn(),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _mediaPreview(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Image.file(
                File(_filePath),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _captureBtn(),
                      _flashBtn(),
                    ],
                  ),
                ),
                if (_isAIEnabled)
                  Expanded(
                    flex: 1,
                    child: _aiBtn(context),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _mediaPreviewWithAI(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(_filePath),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: _onTapUpBox,
                        onPanUpdate: _onPanUpdateBox,
                        child: CustomPaint(
                          painter: BoxPainter(
                            boxes: _boxes,
                            imageSize: _aiImageSize,
                          ),
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _captureBtn(),
                      _flashBtn(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _addBoxBtn(),
                      _removeBoxBtn(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );


  void _onPanUpdateBox(DragUpdateDetails details) {
    int selectedBoxIndex = getSelectedBoxIndex();
    if (selectedBoxIndex < 0 || selectedBoxIndex >= _boxes.length) return;

    _boxes[selectedBoxIndex].move(details.localPosition, details.delta);
    _boxes[selectedBoxIndex].scale(details.localPosition, details.delta);
    _funUpdateUi();
  }

  void _onTapUpBox(TapUpDetails details) {
    int selectedBoxIndex = getSelectedBoxIndex();

    for (int i = 0; i < _boxes.length; i++) {
      _boxes[i].unSelect(details.localPosition);
    }

    for (int i = selectedBoxIndex + 1; i < _boxes.length; i++) {
      if (_boxes[i].toggleSelected(details.localPosition)) break;
    }
    _funUpdateUi();
  }

  int getSelectedBoxIndex() => _boxes.indexWhere((e) => e.isSelected);

  _captureBtn() {
    if (_pictureMode == -1) {
      return IconButton(
          onPressed: _funCaptureImage, icon: const Icon(Icons.camera_alt));
    } else if (_pictureMode == 0) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
        ),
      );
    } else if (_pictureMode == 1 || _pictureMode == 2) {
      return IconButton(onPressed: _funDoneImage, icon: const Icon(Icons.done));
    } else {
      return Container();
    }
  }

  _aiBtn(BuildContext context) {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    return TextButton(
      onPressed: () {
        _funAIImage(scaffoldMessengerState);
      },
      child: const Text('AI'),
    );
  }

  _flashBtn() {
    if (_pictureMode == -1) {
      return IconButton(
        onPressed: _funChangeFlash,
        icon: Icon(_flashOn ? Icons.flashlight_on : Icons.flashlight_off),
      );
    } else if (_pictureMode == 0) {
      return Container();
    } else if (_pictureMode == 1 || _pictureMode == 2) {
      return IconButton(
        onPressed: _funRecaptureImage,
        icon: const Icon(Icons.close),
      );
    } else {
      return Container();
    }
  }

  _addBoxBtn() {
    return IconButton(
      onPressed: _funAddBox,
      icon: const Icon(Icons.add),
    );
  }

  _removeBoxBtn() {
    return IconButton(
      onPressed: _funRemoveBox,
      icon: const Icon(Icons.remove),
    );
  }

  _scaleStart(ScaleStartDetails details) async {
    _baseScale = _currentScale;
  }

  _scaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null || _pointers != 2) return;

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    _controller?.setZoomLevel(_currentScale);
  }

  _onFocusRequest(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) return;

    final offset = Offset(details.localPosition.dx / constraints.maxWidth,
        details.localPosition.dy / constraints.maxHeight);

    _controller?.setExposurePoint(offset);
    _controller?.setFocusPoint(offset);
  }

  String _getData(String key) => (_data[key] ?? '').toString();
}

class Box {
  Box({
    required Rect imageRect,
    required this.color,
    bool isSelected = false,
  })  : _isSelected = isSelected,
        _imageRect = imageRect,
        _canvasSize = imageRect.size,
        _imageSize = imageRect.size;

  Rect _imageRect;
  final Color color;
  bool _isSelected;
  Size _canvasSize;
  Size _imageSize;

  Rect get imageRect => _imageRect;

  Rect get canvasRect => Rect.fromLTRB(
        _canvasSize.width * _imageRect.left / _imageSize.width,
        _canvasSize.height * _imageRect.top / _imageSize.height,
        _canvasSize.width * _imageRect.right / _imageSize.width,
        _canvasSize.height * _imageRect.bottom / _imageSize.height,
      );

  set canvasRect(Rect canvasRect) {
    _imageRect = Rect.fromLTRB(
      _imageSize.width * canvasRect.left / _canvasSize.width,
      _imageSize.height * canvasRect.top / _canvasSize.height,
      _imageSize.width * canvasRect.right / _canvasSize.width,
      _imageSize.height * canvasRect.bottom / _canvasSize.height,
    );
  }

  Rect get innerRect => canvasRect.deflate(30);

  bool get isSelected => _isSelected;

  @override
  String toString() {
    return 'Box(rect: $canvasRect, color: $color, isSelected: $isSelected)';
  }

  void setCanvasSize(Size size) {
    _canvasSize = size;
  }

  void setImageSize(Size? size) {
    if (size == null) return;
    _imageSize = size;
  }

  void move(Offset localPosition, Offset delta) {
    if (!_isSelected || !innerRect.contains(localPosition)) return;
    Rect shiftedRect = canvasRect.shift(delta);
    Rect fullSizeRect =
        Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    bool isShiftedRectInFullSize = fullSizeRect.contains(shiftedRect.topLeft) &&
        fullSizeRect.contains(shiftedRect.bottomRight);
    canvasRect = isShiftedRectInFullSize ? shiftedRect : canvasRect;
  }

  void scale(Offset localPosition, Offset delta) {
    if (!_isSelected ||
        innerRect.contains(localPosition) ||
        !canvasRect.contains(localPosition)) return;

    Rect scaledRect = (localPosition.dy < innerRect.top)
        ? Rect.fromPoints(
            canvasRect.topLeft.translate(0, delta.dy), canvasRect.bottomRight)
        : (localPosition.dy > innerRect.bottom)
            ? Rect.fromPoints(canvasRect.topLeft,
                canvasRect.bottomRight.translate(0, delta.dy))
            : (localPosition.dx < innerRect.left)
                ? Rect.fromPoints(canvasRect.topLeft.translate(delta.dx, 0),
                    canvasRect.bottomRight)
                : Rect.fromPoints(canvasRect.topLeft,
                    canvasRect.bottomRight.translate(delta.dx, 0));
    Rect fullSizeRect =
        Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);
    bool isScaledRectInFullSize = fullSizeRect.contains(scaledRect.topLeft) &&
        fullSizeRect.contains(scaledRect.bottomRight);
    canvasRect = (isScaledRectInFullSize) ? scaledRect : canvasRect;
  }

  bool toggleSelected(Offset localPosition) {
    if (!canvasRect.contains(localPosition)) return false;
    _isSelected = !_isSelected;
    return true;
  }

  bool unSelect(Offset localPosition) {
    if (!canvasRect.contains(localPosition)) return false;
    _isSelected = false;
    return true;
  }
}

class BoxPainter extends CustomPainter {
  BoxPainter({
    required this.boxes,
    required this.imageSize,
  });

  final List<Box> boxes;
  final Size? imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (Box b in boxes) {
      Paint paintStroke = Paint()
        ..color = b.isSelected ? Colors.black : b.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      b.setCanvasSize(size);
      b.setImageSize(imageSize);

      canvas.drawRect(b.canvasRect, paintStroke);

      Paint paintBlackFill = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      if (b.isSelected) canvas.drawRect(b.canvasRect, paintBlackFill);

      Paint paintFill = Paint()
        ..color = b.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        b.isSelected ? b.innerRect : b.canvasRect,
        paintFill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}