import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/firebase_options.dart';
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

  _initialiseFirebase() async {
    try {
      // Initialize Firebase with the correct options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Request notification permissions
      await _notification.requestPermissions();
      
      // Set up foreground notification handler
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle initial message (app opened from terminated state)
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          log("Initial message: ${message.messageId}");
          _notification.onNotification(message);
        }
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        log("Foreground message received: ${message.messageId}");
        _notification.onNotification(message);
      });
      
      // Handle when the app is opened from background via a notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        log("App opened from background via notification: ${message.messageId}");
        _notification.onNotification(message);
      });
      
      // Get the token for this device
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        log("Firebase Token: $token");
        final oldToken = Preference.getStr(Preference.firebaseToken);
        
        // Only update if token has changed
        if (oldToken != token) {
          Preference.setValue(Preference.firebaseToken, token);
          
          // Send the updated token to your backend
          _updateTokenOnServer(token);
        }
      }
      
      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        log("Firebase Token refreshed: $newToken");
        Preference.setValue(Preference.firebaseToken, newToken);
        
        // Send the updated token to your backend
        _updateTokenOnServer(newToken);
      });
      
      // Subscribe to topics based on user role
      _subscribeToTopics();
      
    } catch (e) {
      log("Error initializing Firebase: $e");
    }
  }
  
  Future<void> _updateTokenOnServer(String token) async {
    // Get user ID and role
    final userId = Preference.getStr(Preference.userId);
    if (userId.isEmpty) return;
    
    try {
      // TODO: You would typically call your API here to update the token on the server
      log("Token updated on server for user $userId: $token");
    } catch (e) {
      log("Error updating token on server: $e");
    }
  }
  
  Future<void> _subscribeToTopics() async {
    try {
      // Get user role and ID
      final role = Preference.getStr(Preference.userRole);
      
      // The userId might be stored as an int, so we need to handle that
      final userIdValue = Preference.value(Preference.userId);
      final userId = userIdValue != null ? userIdValue.toString() : "";
      
      if (role.isNotEmpty) {
        // Subscribe to role-specific topic
        await FirebaseMessaging.instance.subscribeToTopic("role_$role");
        log("Subscribed to topic: role_$role");
        
        // Subscribe to user-specific topic
        if (userId.isNotEmpty) {
          final userIdTopic = "user_$userId";
          await FirebaseMessaging.instance.subscribeToTopic(userIdTopic);
          log("Subscribed to topic: $userIdTopic");
        }
        
        // Subscribe to general notifications topic
        await FirebaseMessaging.instance.subscribeToTopic("all_users");
        log("Subscribed to topic: all_users");
      }
    } catch (e) {
      log("Error subscribing to topics: $e");
    }
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
                  'Pending Claims',
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