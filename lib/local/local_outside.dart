import 'package:hive/hive.dart';

import 'hive_box_key.dart';

class OutsideJob {

  static void saveStatus(int jobId, String status) async {
    await Hive.box(HiveBoxKey.outsideJobs).put(jobId.toString(), status);
  }


  static Future<String> getStatus(int jobId) async {
    final data  =  await Hive.box(HiveBoxKey.outsideJobs).get(jobId.toString(), defaultValue: "No");
    return data;
  }

}