




import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/ui/home_screen/home_view_ui.dart';
import 'package:moval/ui/home_screen/tabs/mv_jobs.dart';
import 'package:moval/util/a_notification.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/widget/icon_tab_header_new.dart';

import 'tabs/ms_jobs.dart';
import 'widgets/img_pager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeScreen();
  }
}
class _HomeScreen extends State<HomeScreen> with TickerProviderStateMixin {

  TabController? _tabController;
  int _activeIndex = -1;
  bool _isMVJobs = true;

  final DateController _dateController = DateController();
  final ANotification _notification = ANotification();

  @override
  void initState() {
    _initialiseFirebase();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_funTabListener);

    _showMessageIfExist();

    _loadData();

    super.initState();
  }

  void _loadData() {
    String credentialStr = Preference.getStr(Preference.credential);
    if(credentialStr.isEmpty) return;
    _isMVJobs = (jsonDecode(credentialStr)['platform'] == 0);
  }

  _funTabListener() {
    _activeIndex = _tabController?.index ?? -1;
    Preference.setValue(Preference.currentJob, _activeIndex);
    _funUpdateUi();
  }

  _funUpdateUi() {
    setState(() {});
  }

  _initialiseFirebase () async {
    await Firebase.initializeApp();

    FirebaseMessaging.instance.getInitialMessage().then(_notification.onNotification);
    FirebaseMessaging.onMessage.listen(_notification.onNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_notification.onNotification);
  }

  _showMessageIfExist() async {
    await Future.delayed(const Duration(seconds: 1));

    if (Preference.getInt(Preference.isShowMessageToEmployee) == 1) {
      final date = DateFormat("yyyy-MM-dd").parse(Preference.getStr(Preference.lastDateOfPayment));
      final formattedDate = DateFormat("dd-MM-yyyy").format(date);
      final msg = "Your MOVAL subscription is under extension period. Your Subscription will be expired on Date $formattedDate";

      showDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OKAY",
                style: TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String role = Preference.getStr(Preference.userRole);
    return SafeArea(
        child: HomeView(
            selectedTab: 0,
            showAddBtn: (role != 'employee' && role != 'Branch Contact'),
            child: ImgPager(
              tabs: [
                IconTabHeaderNew(
                  'Pending Jobs',
                  _activeIndex == 0,
                  'solid-task.svg',
                ),
                IconTabHeaderNew(
                  'To Be Approved',
                  _activeIndex == 1,
                  'timer.svg',
                ),
                IconTabHeaderNew(
                  'Approved',
                  _activeIndex == 2,
                  'completed.svg',
                ),
              ],
              tabView: (_isMVJobs)
                  ? [
                      MVJobs(
                        jobType: pending,
                        dateController: _dateController,
                      ),
                      MVJobs(
                        jobType: submitted,
                        dateController: _dateController,
                      ),
                      MVJobs(
                        jobType: approved,
                        dateController: _dateController,
                      ),
                    ]
                  : [
                      MSJobs(
                        jobType: pending,
                        dateController: _dateController,
                      ),
                      MSJobs(
                        jobType: submitted,
                        dateController: _dateController,
                      ),
                      MSJobs(
                        jobType: approved,
                        dateController: _dateController,
                      ),
                    ],
              tabController: _tabController,
              dateController: _dateController,
            )));
  }
}

class DateController {

  final Map _listener = {};
  final List _listenerKeys = [];
  final List _clearKeys = [];

  addListener(Function(String jobType) listener, String jobType) {
    _listenerKeys.add(jobType);
    _listener[jobType] = listener;
  }

  dispose(String jobType) {
    _listener.remove(jobType);
    _listenerKeys.remove(jobType);
  }

  invalidate() {
    for (var key in _listenerKeys) {
      _listener[key]?.call(key);
    }
  }

  invalidateByKey(String key){
    _listener[key]?.call(key);
  }

  addClearDateListener(String key, Function() clearDateListener) {
    _clearKeys.add(key);
    _listener[key] = clearDateListener;
  }

  clearDate() {
    for (var key in _clearKeys) {
      Preference.setValue(key, '');
      _listener[key]?.call();
    }
  }

  disposeClearListener(String key) {
    _listener.remove(key);
    _clearKeys.remove(key);
  }
}