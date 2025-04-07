// job_submission_service.dart

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:moval/api/api.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/widget/a_snackbar.dart';
import '../local/local_jobs.dart';
import '../local/local_outside.dart';
import '../ui/pending_jobs/widget/file_upload_failed.dart';

void setupJobData({
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
  // Print the essential data
  print('Setup Job Data:');
  print('Images: $images');
  print('LocationControllerPosition: $locationControllerPosition');
  print('Data: $data');
  print('Custom Vehicle Images: $customVehicleImagesField');
  print('Custom Document Images: $customDocumentImageField');

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

class JobDataStorage {
  // Singleton instance
  static final JobDataStorage _instance = JobDataStorage._internal();
  factory JobDataStorage() => _instance;
  JobDataStorage._internal();

  // Fields to store data
  BuildContext? context;
  ScaffoldMessengerState? scaffoldMessengerState;
  NavigatorState? navigatorState;
  List<dynamic>? images;
  dynamic locationControllerPosition;
  Map<dynamic, dynamic>? data;
  Map<dynamic, dynamic>? dataSOP;
  List<dynamic>? customVehicleImagesField;
  List<dynamic>? customDocumentImageField;
  Function? retryFailedFile;
  Function? onJobSubmit;
  Function? getData;

  // Set data method
  void setData({
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
    this.context = context;
    this.scaffoldMessengerState = scaffoldMessengerState;
    this.navigatorState = navigatorState;
    this.images = images;
    this.locationControllerPosition = locationControllerPosition;
    this.data = data;
    this.dataSOP = dataSOP;
    this.customVehicleImagesField = customVehicleImagesField;
    this.customDocumentImageField = customDocumentImageField;
    this.retryFailedFile = retryFailedFile;
    this.onJobSubmit = onJobSubmit;
    this.getData = getData;
  }

  bool get hasData =>
      context != null &&
      scaffoldMessengerState != null &&
      navigatorState != null &&
      images != null &&
      data != null &&
      dataSOP != null &&
      customVehicleImagesField != null &&
      customDocumentImageField != null &&
      retryFailedFile != null &&
      onJobSubmit != null &&
      getData != null;
}

Future<void> submitJobData(BuildContext context) async {
  final storage = JobDataStorage();

  // Check if data is available in storage
  if (!storage.hasData) {
    logError("Data not set in JobDataStorage.");
    throw Exception("Data not set in JobDataStorage.");
  }

  // Extract data from storage
  ScaffoldMessengerState scaffoldMessengerState =
      storage.scaffoldMessengerState!;
  NavigatorState navigatorState = storage.navigatorState!;
  List<Map<String, dynamic>> images =
      List<Map<String, dynamic>>.from(storage.images!);
  dynamic locationControllerPosition = storage.locationControllerPosition;
  Map<String, dynamic> data = Map<String, dynamic>.from(storage.data!);
  Map<String, dynamic> dataSOP = Map<String, dynamic>.from(storage.dataSOP!);
  List<Map<String, dynamic>> customVehicleImagesField =
      List<Map<String, dynamic>>.from(storage.customVehicleImagesField!);
  List<Map<String, dynamic>> customDocumentImageField =
      List<Map<String, dynamic>>.from(storage.customDocumentImageField!);
  Function retryFailedFile = storage.retryFailedFile!;
  Function onJobSubmit = storage.onJobSubmit!;
  Function getData = storage.getData!;

  // Log extracted data
  logInfo("Extracted data from storage: ${storage.toString()}");

  // Ensure all images are uploaded
  for (var item in images) {
    if (item['status'] == Api.loading) {
      logWarning("Image upload still in progress for item: ${item['type']}");
      return;
    }
  }

  String files = '';

  // Check for defaultError status in images
  for (var item in images) {
    if (item['status'] == Api.defaultError &&
        !(item['type'] == 'video' ||
            item['type'] == 'other' ||
            item['name'].startsWith('http'))) {
      files = '${files.isEmpty ? '' : '$files, '}${item['type']}';
    }
  }

  // Log failed files
  if (files.isNotEmpty) {
    logError("Files failed to upload: $files");
    final response = await showDialog(
      context: context,
      builder: (builder) => FileUploadFailedDialog(files: files),
    );
    if (response == true) {
      logInfo("Retrying failed file upload.");
      retryFailedFile();
    }
    return;
  }

  // Check for internetError status in images
  for (var item in images) {
    if (item['status'] == Api.internetError &&
        !(item['type'] == 'video' ||
            item['type'] == 'other' ||
            item['name'].startsWith('http')) &&
        (double.parse(item['latitude']) == 0.0 ||
            double.parse(item['longitude']) == 0.0)) {
      logError("Location fetch error for image type: ${item['type']}");
      ASnackBar.showError(scaffoldMessengerState,
          'Recapture image ${item['type']} due to location fetch error.');
      return;
    }
  }

  // Log other image and video processing
  List<String> otherImages = [];
  String videoPath = "";
  for (var image in images) {
    if (image['type'] == 'other') {
      otherImages.add(image['server'] ?? image['name'].split('storage/').last);
      logInfo("Processed other image: ${image['type']}");
    }
    if (image['type'] == 'video') {
      videoPath = image['server'] ?? image['name'].split('storage/').last;
      logInfo("Processed video path: $videoPath");
    }
  }

  // Fetch location
  double lat = locationControllerPosition?.latitude ?? 0;
  double long = locationControllerPosition?.longitude ?? 0;
  String place = '';

  try {
    final placeMark = await placemarkFromCoordinates(lat, long);
    place = '${placeMark.first.subLocality}, ${placeMark.first.locality}';
    logSuccess("Fetched location: $place");
  } catch (e) {
    logError("Error in fetching location: $e");
  } finally {
    LocalJobsStatus.saveJobLatLong(data['id'], lat, long);
    String outside = await OutsideJob.getStatus(data['id']);
    final Map<String, dynamic> imageMap = {for (var v in images) v['type']: v};

    final response = await Api(scaffoldMessengerState).submitMSJobBasicInfo(
      jobId: data['id'],
      sopId: dataSOP['id'],
      vehicleImages:
          (dataSOP['vehichle_images_field_label'] as List?)?.map((e) {
                String label = e['form_field_label'];
                return {
                  'name': label,
                  'path': imageMap[label]['name'],
                  'ai_box_coordinate': imageMap[label]['ai_box'],
                  'final_box_coordinate': imageMap[label]['final_box'],
                };
              }).toList() ??
              [],
      documentImages:
          (dataSOP['document_image_field_label'] as List?)?.map((e) {
                String label = e['form_document_label'];
                return {
                  'name': label,
                  'path': imageMap[label]['name'],
                };
              }).toList() ??
              [],
      customVehicleImages: customVehicleImagesField.map((e) {
        return {
          'name': e['type'],
          'path': e['name'],
          'ai_box_coordinate': e['ai_box'],
          'final_box_coordinate': e['final_box'],
        };
      }).toList(),
      customDocumentImages: customDocumentImageField.map((e) {
        return {
          'name': e['type'],
          'path': e['name'],
        };
      }).toList(),
      remark: getData('remark'),
      isOutside: outside,
      otherImages: otherImages,
      videoFile: (videoPath.isEmpty || videoPath.contains('http'))
          ? null
          : File(videoPath),
      place: place,
      lat: lat.toString(),
      long: long.toString(),
    );

    logInfo("API response: $response");

    if (response is String && response.startsWith(Api.defaultError)) {
      logError("API Error: $response");
      ASnackBar.showError(scaffoldMessengerState, response);
    } else if (response == Api.internetError) {
      logWarning("Internet error occurred.");
      onJobSubmit(true);
    } else if (response == Api.authError) {
      logError("Authentication failed.");
      UiUtils.authFailed(navigatorState);
    } else {
      logSuccess("Job submitted successfully.");
      onJobSubmit(false);
    }
  }
}

void submitJob(BuildContext context, {
  required bool isOffline,
}) async {
  ScaffoldMessengerState scaffoldMessengerState = ScaffoldMessenger.of(context);
  
  // Log the process
  logInfo("Starting job submission process. Offline mode: $isOffline");
  
  // Retrieve data from storage
  var storage = JobDataStorage();
  if (!storage.hasData) {
    logError("JobDataStorage not initialized properly");
    ASnackBar.showError(scaffoldMessengerState, "Data not initialized properly. Please try again.");
    return;
  }
  
  // Extract data from storage
  List<Map<String, dynamic>> images = 
      List<Map<String, dynamic>>.from(storage.images!);
  Function retryFailedFile = storage.retryFailedFile!; // Access the function from storage
  
  // Specifically check for image upload status
  bool hasUploadingImages = false;
  bool hasFailedImages = false;
  String failedImageTypes = '';
  
  for (var item in images) {
    if (item['status'] == Api.loading) {
      hasUploadingImages = true;
      logWarning("Image still uploading: ${item['type']}");
    } else if (item['status'] != Api.success && !item['name'].toString().startsWith('http')) {
      hasFailedImages = true;
      failedImageTypes += "${failedImageTypes.isEmpty ? '' : ', '}${item['type']}";
      logError("Failed image: ${item['type']} - Status: ${item['status']}");
    }
  }
  
  if (hasUploadingImages) {
    ASnackBar.showWarning(scaffoldMessengerState, 
        "Some images are still uploading. Please wait before submitting.");
    return;
  }
  
  if (hasFailedImages) {
    logError("Some images failed to upload: $failedImageTypes");
    final response = await showDialog(
      context: context,
      builder: (builder) => FileUploadFailedDialog(files: failedImageTypes),
    );
    
    if (response == true) {
      logInfo("Retrying failed file uploads");
      retryFailedFile(); // Now correctly using the function from storage
    }
    return;
  }
  
  // All checks passed, proceed with job submission
  await submitJobData(context);
}

// Color codes for terminal output
const String resetColor = '\x1B[0m';
const String redColor = '\x1B[31m';
const String greenColor = '\x1B[32m';
const String yellowColor = '\x1B[33m';
const String blueColor = '\x1B[34m';

// Log info messages
void logInfo(String message) {
  final timestamp = DateTime.now();
  print('$blueColor[INFO][$timestamp]: $message$resetColor');
}

// Log success messages
void logSuccess(String message) {
  final timestamp = DateTime.now();
  print('$greenColor[SUCCESS][$timestamp]: $message$resetColor');
}

// Log warning messages
void logWarning(String message) {
  final timestamp = DateTime.now();
  print('$yellowColor[WARNING][$timestamp]: $message$resetColor');
}

// Log error messages
void logError(String message) {
  final timestamp = DateTime.now();
  print('$redColor[ERROR][$timestamp]: $message$resetColor');
}
