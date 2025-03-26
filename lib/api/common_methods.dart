import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CommonMethods {
  final padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  CommonMethods();
  Future<bool> checkNetwork() async {
/*     var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false; */
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        print("Connected to the Internet");
        return true;
      } else {
        print("No Internet connection");
      }
    } catch (e) {
      print("Error: $e");
    }
    return false; 
  }

  Future<String> changeDateFormat(String date, String format) async {
    final DateTime dateTime = DateTime.parse(date);
    final DateFormat formatter = DateFormat(format);
    final String formatted = formatter.format(dateTime);
    return formatted;
  }

  Future<String> getRadioValue(String selection, String value) async {
    if (selection == value) {
      return '1';
    } else {
      return '0';
    }
  }
}
