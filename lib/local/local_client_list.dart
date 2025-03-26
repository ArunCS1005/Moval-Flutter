import 'package:hive/hive.dart';
import 'package:moval/local/hive_box_key.dart';

class LocalClientList {

  static const clientList = 0;

  static const branchList = 0;

  static const contactPersonList = 0;

  static getClients() async {
    final data = await Hive.box(HiveBoxKey.clientList).get(clientList, defaultValue: []);
    return data;
  }

  static saveClients(data) {
    Hive.box(HiveBoxKey.clientList).put(clientList, data);
  }

  static getBranch() async {
    final data = await Hive.box(HiveBoxKey.branchList).get(branchList, defaultValue: []);
    return data;
  }

  static saveBranch(data) {
    Hive.box(HiveBoxKey.branchList).put(branchList, data);
  }

  static getContactPerson() async {
    final data = await Hive.box(HiveBoxKey.contactPersonList).get(contactPersonList, defaultValue: []);
    return data;
  }

  static saveContactPerson(data) {
    Hive.box(HiveBoxKey.contactPersonList).put(contactPersonList, data);
  }

}