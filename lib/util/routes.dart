import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moval/ui/change_password/change_password_ui.dart';
import 'package:moval/ui/credential/forget_password_ui.dart';
import 'package:moval/ui/credential/set_password_ui.dart';
import 'package:moval/ui/home_screen/home_screen_ui.dart';
import 'package:moval/ui/pending_jobs/pending_jobs.dart';
import 'package:moval/ui/home_screen/search_ui.dart';
import 'package:moval/ui/profile/profile_ui.dart';
import 'package:moval/ui/splash_ui.dart';
import 'package:moval/ui/util_ui/capture_image.dart';
import 'package:moval/ui/util_ui/capture_video.dart';
import '../ui/credential/login_ui.dart';
import '../ui/ms_add_new_job/ms_add_new_job.dart';
import '../ui/mv_add_new_job/mv_add_new_job.dart';
import '../ui/pdf_view/pdf_view.dart';

class Routes {

  static const splash = "/ui/splash_ui";
  static const login = "/ui/credential/login_ui";
  static const setPassword = "/ui/credential/set_password_ui";
  static const forgetPassword = "/ui/credential/forget_password_ui";
  static const msAddNewJob = "/ui/ms_add_new_job/ms_add_new_job.dart";
  static const mvAddNewJob = "/ui/mv_add_new_job/mv_add_new_job.dart";
  static const homeScreen = "/ui/home_screen/home_screen_ui.dart";
  static const verifyOtp = "/ui/home_screen/verify_otp_ui.dart";
  static const captureImage = '/ui/util_ui/capture_image.dart';
  static const captureVideo = '/ui/util_ui/capture_video.dart';
  static const profile = "/ui/profile/profile_ui.dart";
  static const changePassword  = "/ui/change_password/change_password_ui.dart";

  static const search = 'search';
  static const pendingJobs = 'pendingJobs';
  static const pdfView = 'pdfView';

  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _generate(const SplashScreen(), settings);
      case login:
        return _generate(const Login(), settings);
      case setPassword:
        return _generate(const SetPassword(), settings);
      case forgetPassword:
        return _generate(const ForgetPassword(), settings);
      case pendingJobs:
        return _generate(const PendingJobs(), settings);
      case pdfView:
        return _generate(const PDFViewer(), settings);
      case captureImage:
        return _generate(const CaptureImage(), settings);
      case captureVideo:
        return _generate(const CaptureVideo(), settings);
      case msAddNewJob:
        return _generate(const MSAddNewJob(), settings);
      case mvAddNewJob:
        return _generate(const MVAddNewJob(), settings);
      case homeScreen:
        return _generate(const HomeScreen(), settings);
      case search:
        return _generate(const SearchUi(), settings);
      case profile:
        return _generate(const Profile(), settings);
      case changePassword:
        return _generate(const ChangePassword(), settings);
      default:
        return _generate(const Scaffold(), settings);
    }
  }

  static Route<dynamic> _generate(screen, settings) {
    return CupertinoPageRoute(builder: (builder) => screen, settings: settings);
  }
}
