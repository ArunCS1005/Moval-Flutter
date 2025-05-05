import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:moval/api/urls.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';

import '../util/preference.dart';

class Api {
  final ScaffoldMessengerState scaffoldMessengerState;
  final padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  var log = '';

  static const defaultError = 'defaultError';
  static const internetError = 'internetError';
  static const authError = 'authError';
  static const loading = 'loading';
  static const success = 'success';
  static const warning = 'warning';
  static const timeError = 'timeError';
  static const locationError = 'locationError';
  static const gpsError = 'gpsError';
  static const noData = 'noData';
  

  Api(this.scaffoldMessengerState);

  Future login(
    String userId,
    String password,
    int platformIndex,
    String deviceId,
    String firebaseToken,
  ) async {
    try {
      const String uri = loginUrl;
      Map<String, dynamic> body = {
        'email': userId,
        'password': password,
        'deviceId': deviceId,
        'platform': (platformIndex + 1).toString(),
        'firebase_token': firebaseToken
      };

      final response = await http.post(
        Uri.parse(uri),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        encoding: Encoding.getByName('utf-8'),
        body: body,
      );

      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);
      apiLog('Response-\n${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['result'];
      } else if (response.statusCode == 401) {
        return authError + responseBody['result']['error'];
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future setPassword(
    String password,
    String confirmPassword,
    String userId, {
    required int platformIndex,
  }) async {
    try {
      String role = Preference.getStr(Preference.userRole);
      String api = (role == 'employee')
          ? employeeSetPassword.replaceFirst('#employeeId', userId)
          : (role == 'Branch Contact')
              ? branchSetPassword
              : adminSetPassword;

      final response = await http.post(
        Uri.parse(api),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'password': password,
          'password_confirmation': confirmPassword,
          'platform': (platformIndex == 0) ? 'mv' : 'ms',
        },
      );

      Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return success;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return data['result']['error'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future callSendForgotPasswordRequest(String userId, String platformKey) async {
    try {
      final response =
          await http.post(Uri.parse(sendForgotPasswordRequest), headers: {
        'Accept': 'application/json',
      }, body: {
        'platform': platformKey,
        'user_id': userId,
      });

      final body = jsonDecode(response.body);

      dev.log("OTP REQUEST ${response.body}");

      return response.statusCode == 200
          ? 'success${body['result']['id']}'
          : body['message'];
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> callVerifyOtp(String otp, String id) async {
    try {
      String api = verifyOtp.replaceFirst('#id', id);

      final response = await http.post(Uri.parse(api), headers: {
        'Accept': 'application/json',
      }, body: {
        'otp': otp
      });

      final responseBody = jsonDecode(response.body);

      dev.log("OTP Verify OTP-$otp response- ${response.body}");

      return response.statusCode == 200
          ? responseBody['result']
          : responseBody['message'];
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future searchJobsList({
    required String platform,
    required String status,
    String page = '',
    String searchBy = '',
    String fromDate = '',
    String toDate = '',
    String employeeId = '',
    String clientId = '',
    bool onlyOfflineJobs = false,
  }) async {
    try {
      // Explicitly create an ordered map to ensure parameters are consistent
      Map<String, String> params = {};
      
      // Add required parameters first
      params[page.isEmpty ? 'all' : 'page'] = page.isEmpty ? '1' : page;
      params['status'] = status;
      
      // Add platform-specific parameters
      if (platform == platformTypeMS) {
        params['role'] = Preference.getStr(Preference.userRole);
      }
      
      // Add conditional parameters if they have values
      if (searchBy.trim().isNotEmpty) {
        params['search_keyword'] = searchBy.trim();
      }
      
      if (fromDate.isNotEmpty) {
        params['from_date'] = fromDate;
      }
      
      if (toDate.isNotEmpty) {
        params['to_date'] = toDate;
      }
      
      if (employeeId.isNotEmpty) {
        params['employee_id'] = employeeId;
      }
      
      if (clientId.isNotEmpty) {
        params['client_id'] = clientId;
      }
      
      if (onlyOfflineJobs) {
        params['is_offline'] = 'yes';
      }
      
      // Construct the URL explicitly for better debug control
      String baseUrl = (platform == platformTypeMS) ? jobsMSList : jobsMVList;
      List<String> queryParts = [];
      
      params.forEach((key, value) {
        if (value.isNotEmpty) {
          queryParts.add('$key=${Uri.encodeComponent(value)}');
        }
      });
      
      String queryString = queryParts.join('&');
      String fullUrl = '$baseUrl?$queryString';
      
      print("SEARCH API REQUEST: $fullUrl");
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );
      
      print("SEARCH API RESPONSE CODE: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(response.body);
        final resultValues = jsonResult['result']['values'];
        
        print("SEARCH API FOUND: ${resultValues.length} items");
        
        if (resultValues.isEmpty) {
          return Api.noData;
        }
        
        return jsonResult['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        print("SEARCH API ERROR: ${response.body}");
        return defaultError;
      }
    } on SocketException {
      print("SEARCH API: Network error");
      return internetError;
    } catch (e) {
      print("SEARCH API EXCEPTION: $e");
      return defaultError;
    }
  }

  Future approveJob({
    required String jobId,
  }) async {
    try {
      String uri = "$approveJobApi/$jobId";

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json'
        },
      );

      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);
      apiLog('Response-\n${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future getPdfFile({
    required String baseUrl,
    required String jobId,
    required String type,
  }) async {
    try {
      var uri = '$baseUrl?inspection_id=$jobId&type=$type'; 
      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json'
        },
      );

      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);
      apiLog('Response-\n${response.body}');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future createMSJob(Map<String, dynamic> body) async {
    try {
      const uri = addMSJob;
      final response = await http.post(
        Uri.parse(uri),
        body: body.map((k, v) => MapEntry(k, v.toString())),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      dev.log('Add Job--->$uri --> ${body.toString()}');
      dev.log('Add Job--->$responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future assignMSJob(Map<String, dynamic> body) async {
    try {
      const uri = assignMSJobUrl;
      final response = await http.post(
        Uri.parse(uri),
        body: body.map((k, v) => MapEntry(k, v.toString())),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      dev.log('assignMSJob--->$uri');
      dev.log('assignMSJob--->$responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future createMVJob(Map<String, dynamic> body) async {
    try {
      const uri = addMVJob;
      final response = await http.post(
        Uri.parse(uri),
        body: body.map((k, v) => MapEntry(k, v.toString())),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          "Content-Type": "application/x-www-form-urlencoded",
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
      );

      dev.log('Add Job--->$uri');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future getJobDetail({
    required String platform,
    required String jobId,
  }) async {
    try {
      final uri = ((platform == platformTypeMS) ? jobMSDetail : jobMVDetail)
          .replaceFirst('#jobId', jobId);

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future predictAccidentAI({
    required String imageUrl,
  }) async {
    try {
      const uri = predictAIApi;

      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request = await httpClient.postUrl(Uri.parse(uri));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode({
        'image_url': imageUrl,
      })));
      HttpClientResponse response = await request.close();
      // todo - you should check the response.statusCode
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();

      final body = jsonDecode(reply);
      if (response.statusCode == 200) {
        return body['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future uploadMSFile({
    required File file,
  }) async {
    try {
      const uri = uploadMSJobFile;
      final header = {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      };

      // Check if file exists
      if (!await file.exists()) {
        apiLog('uploadMSFile - File does not exist: ${file.path}');
        return 'File not found';
      }

      double fileSize = file.lengthSync() / 1024;
      apiLog('uploadMSFile - FileSize = $fileSize');

      // Try to compress the image
      Uint8List? result;
      try {
        result = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: 50,
          minHeight: 250,
        );
      } catch (e) {
        // Fall back to original file if compression fails
        apiLog('uploadMSFile - Compression failed: $e. Using original file.');
        result = await file.readAsBytes();
      }

      if (result == null) return defaultError;

      double resSize = (result.length) / 1024;
      apiLog('uploadMSFile - ResSize = $resSize');
      final body = {
        'file': 'data:image/jpeg;base64,${base64Encode(result)}',
      };

      final response = await http.post(
        Uri.parse(uri),
        body: body.map((k, v) => MapEntry(k, v.toString())),
        headers: header,
        encoding: Encoding.getByName('utf-8'),
      );
      
      apiLog('uploadMSFile- $uri', flag: true);
      apiLog('uploadMSFile Headers- ${response.headers}', flag: true);
      apiLog('uploadMSFile Response Code- ${response.statusCode}', flag: true);
      apiLog('uploadMSFile Response-\n${response.body}');
      
      // Parse the response
      try {
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Fix: Access the correct path in the response structure
          if (responseBody['success'] == true && responseBody['result'] != null) {
            // Return the full URL path from the response
            return responseBody['result']['path'];
          } else {
            apiLog('uploadMSFile - Unexpected response format: ${response.body}');
            return defaultError;
          }
        } else if (response.statusCode == 401) {
          return authError;
        } else {
          return defaultError + (responseBody['message'] ?? '');
        }
      } catch (e) {
        apiLog('uploadMSFile - Error parsing response: $e');
        return defaultError;
      }
    } on SocketException {
      apiLog('uploadMSFile - Network error');
      return internetError;
    } catch (e) {
      apiLog('uploadMSFile - Error: $e');
      return defaultError;
    }
  }

  Future uploadMVFile({
    required int jobId,
    required String type,
    required File file,
  }) async {
    try {
      final uri = uploadMVJobFile.replaceFirst('#jobId', '$jobId');
      final fields = {'type': type};
      final header = {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      };
      final file0 = http.MultipartFile(
        'file',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: (file.path),
      );

      var request = http.MultipartRequest('POST', Uri.parse(uri))
        ..headers.addAll(header)
        ..fields.addAll(fields)
        ..files.add(file0);

      final response = await request.send();
      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);

      final convertedResponse = await response.stream.bytesToString();
      apiLog('Response-\n$convertedResponse');
      return response.statusCode == 200
          ? jsonDecode(convertedResponse)['result']['name']
          : defaultError;
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future submitMSJobBasicInfo({
    required int jobId,
    required int sopId,
    required List vehicleImages,
    required List documentImages,
    required List customVehicleImages,
    required List customDocumentImages,
    required String remark,
    required String isOutside,
    required List otherImages,
    required File? videoFile,
    required String place,
    required String lat,
    required String long,
  }) async {
    try {
      const uri = submitMSJobImageOrVideo;
      
      // Calculate and add total counts for backend tracking
      int totalVehicleImages = vehicleImages.length + customVehicleImages.length;
      int totalDocumentImages = documentImages.length + customDocumentImages.length;

      
      final body = {
        'inspection_id': jobId,
        'sop_id': sopId,
        'vehichle_images_field_post': vehicleImages,
        'document_images_field_post': documentImages,
        'custom_vehichle_images_field_post': customVehicleImages,
        'custom_document_images_field_post': customDocumentImages,
        'total_vehicle_images': totalVehicleImages,
        'total_document_images': totalDocumentImages,
        'job_remark': remark,
        'video_file': videoFile,
      };

      dev.log(
          'C1: waiting for httpResponse: $uri-> ${UiUtils.getRawJsonData(body)}');

      final response = await http.post(
        Uri.parse(uri),
        body: jsonEncode(body),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Content-Type': 'application/json',
        },
      );
      apiLog('submitMSJobBasicInfo URL- $uri', flag: true);
      apiLog('submitMSJobBasicInfo Headers- ${response.headers}', flag: true);
      apiLog('submitMSJobBasicInfo Response Code- ${response.statusCode}',
          flag: true);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return success;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future submitMSJobSignature({
    required int jobId,
    required String signatureUrl,
  }) async {
    try {
      const uri = submitMSJobSignatureUrl;
      final body = {
        'inspection_id': jobId,
        'signature': signatureUrl,
      };
      final response = await http.post(
        Uri.parse(uri),
        body: jsonEncode(body),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return success;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future submitMVJobBasicInfo({
    required int jobId,
    required String remark,
    required String isOutside,
    required List otherImages,
    required String videoPath,
    required String place,
    required String lat,
    required String long,
  }) async {
    try {
      final uri = submitMVJobImageOrVideo.replaceFirst('#jobId', '$jobId');
      final body = {
        'remark': remark,
        'is_outside_job': isOutside,
        'other_images': jsonEncode(otherImages),
        'video_path': videoPath,
        'inspection_place': place,
        'latitude': lat,
        'longitude': long
      };

      final response = await http.post(
        Uri.parse(uri),
        body: body,
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return success;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future updateMSJobDetail(int jobId, Map body) async {
    try {
      final uri = updateMSJobDetailURL.replaceFirst('#jobId', jobId.toString());
      dev.log("body - $body");

      final response = await http.put(Uri.parse(uri),
          body: body.map((k, v) => MapEntry(k, v.toString())),
          headers: {
            'Authorization': Preference.getStr(Preference.userToken),
            'Accept': 'application/json',
          });

      dev.log("Response - ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future submitJobDetail(int jobId, Map body) async {
    try {
      final uri = submitJobVehicleTechnicalDetail.replaceFirst(
          '#jobId', jobId.toString());
      final postBody = {};
      body.forEach((k, v) {
        postBody[k] = v == null ? '' : v.toString();
      });

      print("body - $postBody");

      final response = await http.put(Uri.parse(uri), body: postBody, headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("Response - ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError + responseBody['message'];
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future getVehicleConstantData() async {
    try {
      String uri = vehicleDetailListApi;

      final response = await http.post(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> postSubmitJobVehicleDetail(String jobId, Map body) async {
    try {
      String uri = submitJobVehicleTechnicalDetail;
      if (uri.contains('#jobId')) {
        uri = uri.replaceFirst('#jobId', jobId);
      }

      final response = await http.put(
        Uri.parse(uri),
        body: body,
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json',
        },
      );

      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);
      apiLog('Response-\n${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getVehicleVariantList(int makerId) async {
    try {
      String uri =
          vehicleVariantApi.replaceFirst('#makerId', makerId.toString());

      final response = await http.post(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result']['vehicle_variants'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getClientList({
    required String platform,
    int? branchId,
  }) async {
    try {
      String uri = (platform == platformTypeMS)
          ? (branchId == null)
              ? clientMSList
              : '$clientFromBranchList/$branchId'
          : (branchId == null)
              ? clientList
              : '$clientFromBranchList/$branchId';
      final body = (branchId == null)
          ? {'all': '1', 'search_keyword': '', 'request_type': 'drop_down'}
          : null;

      final response = await http.get(
          Uri.parse("$uri${(body == null) ? '' : '?${_encodeUrl(body)}'}"),
          headers: {
            'Authorization': Preference.getStr(Preference.userToken),
            'Accept': 'application/json',
          });

      dev.log("getClientList -> $uri");
      dev.log("getClientList response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getSOPById({required int id}) async {
    try {
      String uri = '$sopUrl/$id';
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getSOPById -> $uri");
      dev.log("getSOPById response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result']['sop_master'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getJobFiles({required int id}) async {
    try {
      String uri = '$jobFilesUrl?inspection_id=$id';
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getJobFiles -> $uri");
      
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body)['result']['values'];
        
        // Log detailed image counts from the server response
        dev.log("===== FETCHED IMAGE COUNT =====");
        
        int vehicleImagesCount = 0;
        int documentImagesCount = 0;
        
        // Count images from structured data
        if (result['vehichle_images_field_label'] != null) {
          try {
            List<dynamic> vehicleImages = json.decode(result['vehichle_images_field_label'] ?? '[]');
            vehicleImagesCount += vehicleImages.length;
            dev.log("Standard vehicle images: ${vehicleImages.length}");
          } catch (e) {
            dev.log("Error parsing vehicle images: $e");
          }
        }
        
        if (result['custom_vehichle_images_field_label'] != null) {
          try {
            List<dynamic> customVehicleImages = json.decode(result['custom_vehichle_images_field_label'] ?? '[]');
            vehicleImagesCount += customVehicleImages.length;
            dev.log("Custom vehicle images: ${customVehicleImages.length}");
          } catch (e) {
            dev.log("Error parsing custom vehicle images: $e");
          }
        }
        
        if (result['document_image_field_label'] != null) {
          try {
            List<dynamic> documentImages = json.decode(result['document_image_field_label'] ?? '[]');
            documentImagesCount += documentImages.length;
            dev.log("Standard document images: ${documentImages.length}");
          } catch (e) {
            dev.log("Error parsing document images: $e");
          }
        }
        
        if (result['custom_document_image_field_label'] != null) {
          try {
            List<dynamic> customDocumentImages = json.decode(result['custom_document_image_field_label'] ?? '[]');
            documentImagesCount += customDocumentImages.length;
            dev.log("Custom document images: ${customDocumentImages.length}");
          } catch (e) {
            dev.log("Error parsing custom document images: $e");
          }
        }
        

        return result;
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      dev.log("Error in getJobFiles: $e");
      return defaultError;
    }
  }

  Future<dynamic> getBranchList({int? clientId, int? adminId}) async {
    try {
      String uri = (clientId == null)
          ? '$branchList/${adminId ?? -1}'
          : clientBranchList;
      final body = (clientId == null)
          ? {
              'page': 'all',
            }
          : {
              'all': '1',
              'client_id': clientId,
            };
      final response =
          await http.get(Uri.parse("$uri?${_encodeUrl(body)}"), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("branch list-> $uri");
      dev.log("branch list prams -> ${_encodeUrl(body)}");
      dev.log("branch list response -> ${response.body}");

      Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getClientBranchList({required int clientId}) async {
    try {
      String uri = clientBranchMSList;
      final body = {
        'all': '1',
        'client_id': clientId,
      };
      final response =
          await http.get(Uri.parse('$uri?${_encodeUrl(body)}'), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getClientBranchList -> $uri");
      dev.log("getClientBranchList response -> ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getWorkshopList({
    required int branchId,
  }) async {
    try {
      String uri = '$workshopList/$branchId';
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getWorkshopList -> $uri");
      dev.log("getWorkshopList response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getWorkshopBranchList({required int workshopId}) async {
    try {
      String uri = '$workshopBranchList/$workshopId';
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getWorkshopBranchList -> $uri");
      dev.log("getWorkshopBranchList response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result']['values'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getSopList({
    required int branchId,
  }) async {
    try {
      String uri = '$sopList/$branchId';
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      dev.log("getWorkshopList -> $uri");
      dev.log("getWorkshopList response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getContactPersonList({
    int? branchId,
    int? workshopBranchId,
  }) async {
    try {
      String uri = (branchId == null) ? contactPersonMSList : contactPersonList;
      final body =
          (branchId == null) ? null : {'all': '1', 'branch_id': branchId};

      final response = await http.get(
          Uri.parse(
              "$uri${(body == null) ? '/$workshopBranchId' : '?${_encodeUrl(body)}'}"),
          headers: {
            'Authorization': Preference.getStr(Preference.userToken),
            'Accept': 'application/json',
          });

      dev.log("contact person-> $uri");
      dev.log("contact person response -> ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> getEmployeeList() async {
    try {
      String uri = employeeList;
      final body = {
        'all': '1',
        'request_type': 'assignEmployee',
      };

      final response =
          await http.get(Uri.parse("$uri?" + _encodeUrl(body)), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  Future<dynamic> callChangePasswordApi(
      oldPassword, newPassword, confirmPassword) async {
    try {
      final uri = '$changePassword?' +
          _encodeUrl({
            'old_password': oldPassword,
            'password': newPassword,
            'password_confirmation': confirmPassword,
          });

      final response = await http.post(Uri.parse(uri), headers: {
        'Authorization': Preference.getStr(Preference.userToken),
        'Accept': 'application/json',
      });

      apiLog('URL- $uri', flag: true);
      apiLog('Headers- ${response.headers}', flag: true);
      apiLog('Response Code- ${response.statusCode}', flag: true);
      apiLog('Response-\n${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['result'];
      } else if (response.statusCode == 401) {
        return authError;
      } else {
        return defaultError;
      }
    } on SocketException {
      return internetError;
    } catch (e) {
      return defaultError;
    }
  }

  _encodeUrl(Map<String, dynamic> map) {
    // Create a filtered list of parameters (only include non-empty values)
    List<String> validParams = [];
    
    map.forEach((k, v) {
      // Only include parameters with non-empty values
      if (v != null && v.toString().isNotEmpty) {
        validParams.add('$k=${Uri.encodeComponent(v.toString())}');
      }
    });
    
    // Join with ampersands to create a valid query string
    return validParams.join('&');
  }

  apiLog(Object? object, {flag = false}) {
    log = '$log\n${object ?? 'null'}';

    if (flag) {
      return;
    }

    dev.log(log);
  }

  apiSnackBar(String msg, int colorCode) {
    var bg = Colors.green;

    switch (colorCode) {
      case 0:
        bg = Colors.red;
        break;
      case 1:
        bg = Colors.green;
        break;
    }

    scaffoldMessengerState.showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        padding: padding,
        backgroundColor: bg,
      ),
    );
  }

  static Future<bool> networkAvailable() async {
    final response = await Connectivity().checkConnectivity();

    return response == ConnectivityResult.mobile ||
        response == ConnectivityResult.wifi;
  }
}
