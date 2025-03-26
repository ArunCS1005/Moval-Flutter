import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moval/local/hive_box_key.dart';
import 'package:moval/ui/splash_ui.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const SplashScreen(),
      onGenerateRoute: Routes.generateRoutes,
    );
  }
}