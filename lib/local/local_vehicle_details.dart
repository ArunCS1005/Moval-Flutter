import 'package:hive/hive.dart';
import 'package:moval/local/hive_box_key.dart';

class LocalVehicleDetails {

  static const _vehicleDetails = 0;

  static getVehicleColor() async {
    final data = await getVehicleDetails();
    return data['vehicle_colors'] ?? [];
  }

  static getVehicleClass() async {
    final data = await getVehicleDetails();
    return data['vehicle_class'] ?? [];
  }

  static getVehicleBodyTypes() async {
    final data = await getVehicleDetails();
    return data['vehicle_body_type'] ?? [];
  }

  static getVehicleMakers() async {
    final data = await getVehicleDetails();
    return data['vehicle_makers'] ?? [];
  }

  static getVehicleIssueAuthority() async {
    final data = await getVehicleDetails();
    return data['vehicle_issue_authority'] ?? [];
  }

  static getVehicleDetails() async {
    final data = await Hive.box(HiveBoxKey.vehicleDetails).get(_vehicleDetails);
    return data ?? {};
  }

  static saveVehicleDetails(dynamic data) async {
    await Hive.box(HiveBoxKey.vehicleDetails).put(_vehicleDetails, data);
  }
}

class LocalVehicleVariants {

  static getVehicleVariant(int vehicleMakerId) async {
    final data = await Hive.box(HiveBoxKey.vehicleVariants).get(vehicleMakerId);
    return data ?? [];
  }

  static saveVehicleVariant(int vehicleMakerId, dynamic vehicleVariantData) async {
    await Hive.box(HiveBoxKey.vehicleVariants).put(vehicleMakerId, vehicleVariantData);
  }

}