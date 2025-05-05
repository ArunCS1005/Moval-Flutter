import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moval/local/hive_box_key.dart';
import 'package:moval/ui/splash_ui.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/util/a_notification.dart';
import 'firebase_options.dart';

// Define the background message handler outside of any class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Handle the message
  print("Handling a background message: ${message.messageId}");
  
  // You can optionally show a notification here
  final notification = ANotification();
  await notification.onNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the background message handler for Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  await Preference.initialize();
  await Hive.initFlutter();
  await Hive.openBox(HiveBoxKey.credential);
  await Hive.openBox(HiveBoxKey.jobs);
  await Hive.openBox(HiveBoxKey.jobDetails);
  await Hive.openBox(HiveBoxKey.vehicleDetails);
  await Hive.openBox(HiveBoxKey.vehicleVariants);
  await Hive.openBox(HiveBoxKey.clientList);
  await Hive.openBox(HiveBoxKey.branchListAll);
  await Hive.openBox(HiveBoxKey.jobsStatus);
  await Hive.openBox(HiveBoxKey.outsideJobs);
  await Hive.openBox(HiveBoxKey.branchList);
  await Hive.openBox(HiveBoxKey.contactPersonList);
  await clearCacheOnStart();
  runApp(const MyApp());
}

Future<void> clearCacheOnStart() async {
  var box = await Hive.openBox('mediaCache');
  await box.clear();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: const SplashScreen(),
        onGenerateRoute: Routes.generateRoutes,
      ),
    );
  }
}