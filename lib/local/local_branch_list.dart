import 'package:hive/hive.dart';
import 'package:moval/local/hive_box_key.dart';

class LocalBranchList {
  static const branchListAll = 0;

  static getAllBranch() async {
    final data = await Hive.box(HiveBoxKey.branchListAll).get(branchListAll, defaultValue: []);
    return data;
  }

  static saveAllBranch(data) {
    Hive.box(HiveBoxKey.branchListAll).put(branchListAll, data);
  }
}