
import 'package:hive/hive.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/hive_box_key.dart';

class LocalJobs {

  static const _pendingJobKey = 1;
  static const _submittedJobKey = 2;
  static const _approvedJobKey = 3;
  static const _offlineJobKey = 4;

  static _getPendingJobs({required String platformType}) async {
    final data = await Hive.box(HiveBoxKey.jobs)
        .get(platformType + _pendingJobKey.toString(), defaultValue: []);
    return data;
  }

  static _getSubmittedJobs({required String platformType}) async {
    final data = await Hive.box(HiveBoxKey.jobs)
        .get(platformType + _submittedJobKey.toString(), defaultValue: []);
    return data;
  }

  static _getApprovedJobs({required String platformType}) async {
    final data = await Hive.box(HiveBoxKey.jobs)
        .get(platformType + _approvedJobKey.toString(), defaultValue: []);
    return data;
  }

  static _getOfflineJobs({required String platformType}) async {
    final data = await Hive.box(HiveBoxKey.jobs)
        .get(platformType + _offlineJobKey.toString(), defaultValue: []);
    return data;
  }

  static _savePendingJobs({
    required String platformType,
    required List values,
  }) {
    Hive.box(HiveBoxKey.jobs).put(
      platformType + _pendingJobKey.toString(),
      values,
    );
  }

  static _saveSubmittedJobs({
    required String platformType,
    required List values,
  }) {
    Hive.box(HiveBoxKey.jobs).put(
      platformType + _submittedJobKey.toString(),
      values,
    );
  }

  static _saveOfflineJobs({
    required String platformType,
    required List values,
  }) {
    Hive.box(HiveBoxKey.jobs)
        .put(platformType + _offlineJobKey.toString(), values);
  }

  static _saveApprovedJobs({
    required String platformType,
    required List values,
  }) {
    Hive.box(HiveBoxKey.jobs).put(
      platformType + _approvedJobKey.toString(),
      values,
    );
  }

  static addOfflineJob({
    required String platformType,
    required Map job,
  }) async {
    final data = await _getOfflineJobs(platformType: platformType);
    job['id'] = -(data.length + 1);
    job['job_status'] = pending;
    data.insert(0, job);
    _saveOfflineJobs(platformType: platformType, values: data);
  }

  static removeOfflineJob({
    required String platformType,
    required int id,
  }) async {
    final data = await _getOfflineJobs(platformType: platformType);
    for (var job in data) {
      if (job['id'] != id) continue;
      data.remove(job);
      _saveOfflineJobs(platformType: platformType, values: data);
      break;
    }
  }

  static saveJobs({
    required String platformType,
    required String jobType,
    required List data,
  }) {
    final List values = [];
    values.addAll(data);
    switch (jobType) {
      case pending:
        _savePendingJobs(
          values: values,
          platformType: platformType,
        );
        break;
      case submitted:
        _saveSubmittedJobs(
          values: values,
          platformType: platformType,
        );
        break;
      case approved:
        _saveApprovedJobs(
          values: values,
          platformType: platformType,
        );
        break;
    }
  }

  static getJobs({
    required String platformType,
    required String jobType,
  }) {
    switch (jobType) {
      case pending:
        return _getPendingJobs(platformType: platformType);
      case submitted:
        return _getSubmittedJobs(platformType: platformType);
      case approved:
        return _getApprovedJobs(platformType: platformType);
      case offline:
        return _getOfflineJobs(platformType: platformType);
    }
  }
}

class LocalJobsDetail {

  static getJobDetailById(int id) async {
    final data = await Hive.box(HiveBoxKey.jobDetails).get(id.toString(), defaultValue: {});
    return data;
  }

  static saveJobDetailById(int id, dynamic detail) async {
    Hive.box(HiveBoxKey.jobDetails).put(id.toString(), detail);
  }

  static updateJobVehicleDetail(int id, Map detail) async {
    final data = await getJobDetailById(id);
    detail.forEach((k, v) => data['job_detail'][k] = v);
    saveJobDetailById(id, data);
  }

  static updateJobBasicInfo(int id, Map basicInfo) async {
    final data = await getJobDetailById(id);
    basicInfo.forEach((k, v) => data[k] = v);
    saveJobDetailById(id, data);
  }

  static getJobBasicInfo(int id) async {
    final data = await getJobDetailById(id);
    return {
      'remark': data.putIfAbsent('remark', () => ''),
      'images': data.putIfAbsent('images', () => [])
    };
  }

  static getJobJobDetail(int id) async {
    final data = await getJobDetailById(id);
    return {
      'job_detail': data.putIfAbsent('job_detail', () => {})
    };
  }

  static removeJobDetailById(int id) async {
    Hive.box(HiveBoxKey.jobDetails).delete(id.toString());
  }

  static updateJobId(int offlineId, int serverId) async {
    final data = await getJobDetailById(offlineId);
    data['id'] = serverId;
    saveJobDetailById(serverId, data);
    removeJobDetailById(offlineId);
  }

  static getAllDetail() async {

    final box = Hive.box(HiveBoxKey.jobDetails);
    List data = [];

    for (var key in box.keys) {
      data.add(box.get(key));
    }

    return data;
  }

  static clearAll() async {
    Hive.box(HiveBoxKey.jobDetails).clear();
  }

}


class LocalJobsStatus {

  static const basicInfo = 'basic';
  static const detail = 'detail';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const all    = 'all';
  static const checkLocation = 'checkLocation';


  static _getJob(int id) async {
    final data = await Hive.box(HiveBoxKey.jobsStatus).get(id.toString(), defaultValue: {});
    return data;
  }

  static _saveJob(int id, Map data) async {
    Hive.box(HiveBoxKey.jobsStatus).put(id.toString(), data);
  }

  static _deleteJob(int id) async {
    Hive.box(HiveBoxKey.jobsStatus).delete(id.toString());
  }

  static getJobStatus(int id) async {
    final data = await _getJob(id);
    data.putIfAbsent(basicInfo, () => false);
    data.putIfAbsent(detail, () => false);
    data.putIfAbsent(all, () => false);
    data.putIfAbsent(checkLocation, ()=> false);
    return data;
  }

  static getJobStatusIsOffline(int id, String what) async {
    final data = await _getJob(id);
    return data[what] ?? false;
  }

  static saveJobStatusIsOffline(int id, String what, bool flag) async {
    final data = await _getJob(id);
    data[what] = flag;
    _saveJob(id, data);
  }


  static saveJobLatLong(int id, double lat, double long) async {
    final data = await _getJob(id);
    data[latitude] = lat;
    data[longitude] = long;
    _saveJob(id, data);
  }


  static updateId(int oldId, int newId) async {
    final data = await _getJob(oldId);
    await _saveJob(newId, data);
    await _deleteJob(oldId);
  }

}