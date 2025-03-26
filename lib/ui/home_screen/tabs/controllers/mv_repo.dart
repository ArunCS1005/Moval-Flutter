import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:moval/api/api.dart';
import 'package:moval/api/urls.dart';
import '../../../../api/model/search_model.dart';
import '../../../../util/preference.dart';

class JobsRepository {
  Future<dynamic> searchJobsList({
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
      String uri =
          "${(platform == platformTypeMS) ? jobsMSList : jobsMVList}?${_encodeUrl(
        {
          page.isEmpty ? 'all' : 'page': page.isEmpty ? '1' : page,
          'status': status,
          'search_keyword': searchBy,
          'from_date': fromDate,
          'to_date': toDate,
          'employee_id': employeeId,
          'client_id': clientId,
          'is_offline': onlyOfflineJobs ? 'yes' : '',
          if (platform == platformTypeMS)
            'role': Preference.getStr(Preference.userRole),
        },
      )}";

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': Preference.getStr(Preference.userToken),
          'Accept': 'application/json'
        },
      );

      apiLog('URL- $uri');
      apiLog('Headers- ${response.headers}');
      apiLog('Response Code- ${response.statusCode}');
      apiLog('Response-\n${response.body}');

      final jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 &&
          jsonResponse['result']['values'] != []) {
        return searchJobsListFromJson(response.body);
      } else if (jsonResponse['result']['values'] == []) {
        return Api.noData;
      } else if (response.statusCode == 401) {
        return Api.authError; // Use consistent constants
      } else {
        return Api.defaultError; // Use consistent constants
      }
    } on SocketException {
      return Api.internetError; // Use consistent constants
    } catch (e) {
      return Api.defaultError; // Use consistent constants
    }
  }

  String _encodeUrl(Map<String, dynamic> map) {
    List<String> encodedParams = [];

    map.forEach((key, value) {
      if (value.isNotEmpty) {
        encodedParams.add(
            "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}");
      }
    });

    return encodedParams.join('&');
  }

  void apiLog(String s) {
    print(s); // Ensure proper logging mechanism
  }
}
