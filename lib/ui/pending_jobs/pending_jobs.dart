import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moval/api/api.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/ui/pending_jobs/widget/location_disable.dart';
import 'package:moval/ui/pending_jobs/widget/pager.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/util/location_controller.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/widget/a_snackbar.dart';
import 'package:moval/widget/a_text.dart';

import 'tabs/ms_survey_details.dart';
import 'tabs/ms_upload/ms_upload_images.dart';
import 'tabs/mv_basic_info.dart';
import 'tabs/mv_technical_features.dart';
import 'tabs/mv_vehicle_details.dart';

class PendingJobs extends StatefulWidget {
  const PendingJobs({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<PendingJobs> with TickerProviderStateMixin {
  TabController? _tabController;
  StreamSubscription? _locationStreamSubscription;
  StreamSubscription? _locationStatusStreamSubscription;
  int _activeIndex = 0;
  int _backTapCount = 0;
  final Map<String, dynamic> _data = {'id': -1};
  final Map _jobStatus = {};
  final PagerController _pagerController = PagerController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getDetail();
      _tabController = TabController(
          length: (_data['platform'] == platformTypeMS) ? 2 : 3, vsync: this)
        ..addListener(_funTabListener);
    });
    _pagerController.addListener(_funPagerListener);
    _pagerController.addJobCreateFunction(_createJob2);
  }


  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _locationStatusStreamSubscription?.cancel();
    super.dispose();
  }

  _showAwaitingDialog() async {
    if (_data['is_offline'] == 'yes' || _data['job_status'] == submitted) return;

    /*final response = await showDialog(
        context: context,
        builder: (builder)=> const WaitingDialog(),
        barrierDismissible: false
    );

    if(response == null) Navigator.pop(context);*/

  }


  _getLiveLocation() async {
    const locationSetting =
        LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1);

    LocationController.addGPSDialogHandler(_funGPSHandler);

    _locationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSetting)
            .listen(LocationController.updatePosition);

    _locationStreamSubscription?.onError(LocationController.onError);

    _locationStatusStreamSubscription = Geolocator.getServiceStatusStream()
        .listen(LocationController.onGPSChange);
  }

  _funGPSHandler(bool value) {

    if(value) {
      LocationController.dialogShowing = true;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (builder) => const LocationDisable()).then((value) {
        if (value == null && LocationController.dialogShowing) {
          Navigator.pop(context);
        } else {
          _showAwaitingDialog();
        }
      });
    } else if(LocationController.dialogShowing) {
      LocationController.dialogShowing = false;
      Navigator.pop(context);
    }

  }


  _funTabListener() {
    if ((_tabController?.index ?? 0) > _activeIndex) {
      _tabController?.animateTo(_activeIndex);
      _updateUi;
      return;
    }
    _activeIndex = _tabController?.index ?? 0;
    _pagerController.setCurrentPage(_activeIndex);
    _updateUi;
  }

  void _funPagerListener(int moveTo) {
    if (moveTo == -1) {
      _updateUi;
      return;
    }
    _activeIndex = moveTo;
    _tabController?.animateTo(moveTo);
    _updateUi;
  }

  _getDetail() async {
    ModalRoute? modalRoute = ModalRoute.of(context);
    _data['id'] = -1;
    _data
        .addAll((modalRoute?.settings.arguments ?? {}) as Map<String, dynamic>);
    if (Preference.getBool(Preference.isGuest)) {
      _data['id'] = int.parse(Preference.getStr(Preference.guestJobId));
    }
    _data['images'] = [];
    _data['job_detail'] = {};
    _updateUi;

    _showAwaitingDialog();

    _jobStatus.addAll(await LocalJobsStatus.getJobStatus(_data['id']));
    _jobStatus[LocalJobsStatus.all] = _jobStatus[LocalJobsStatus.basicInfo] &&
        _jobStatus[LocalJobsStatus.detail];

    log('C53: Data: $_data');
    if (_data['id'].isNegative) {
      _createJob(_jobStatus[LocalJobsStatus.all]);
    } else if (_jobStatus[LocalJobsStatus.all]) {
      _loadLocalData();
    } else {
      _loadServerData();
    }
  }

  _createJob(bool allOfflineSaved) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    final response = (_data['platform'] == platformTypeMS)
        ? await Api(scaffoldMessengerState).createMSJob(_data)
        : await Api(scaffoldMessengerState).createMVJob(_data);

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _loadLocalData();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      log("Job created $response");

      await LocalJobs.removeOfflineJob(
          platformType: platformTypeMV, id: _data['id']);
      await LocalJobsDetail.updateJobId(_data['id'], response['id']);
      await LocalJobsStatus.updateId(_data['id'], response['id']);
      _data['id'] = response['id'];
      _updateUi;
      Preference.setValue('offline', 'reload');

      allOfflineSaved ? _loadLocalData() : _loadServerData();
    }

  }


  Future _createJob2() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    final response = (_data['platform'] == platformTypeMS)
        ? await Api(scaffoldMessengerState).createMSJob(_data)
        : await Api(scaffoldMessengerState).createMVJob(_data);

    if (response == Api.defaultError) {
      return _data['id'];
    } else if (response == Api.internetError) {
      return _data['id'];
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      log("Job created $response");

      await LocalJobs.removeOfflineJob(
          platformType: platformTypeMV, id: _data['id']);
      await LocalJobsDetail.updateJobId(_data['id'], response['id']);
      await LocalJobsStatus.updateId(_data['id'], response['id']);
      _data['id'] = response['id'];
      _updateUi;
      Preference.setValue('offline', 'reload');

      return _data['id'];
    }
  }


  _loadServerData() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getJobDetail(
      platform: _data['platform'],
      jobId: _data['id'].toString(),
    );

    log('C52: Response: $response');
    if (response == Api.defaultError) {
      _pagerController.invalidatePage(Api.defaultError);
    } else if (response == Api.internetError) {
      _loadLocalData();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      response.forEach((k, v) => _data[k] = v);

      if (_jobStatus[LocalJobsStatus.basicInfo]) {
        final data = await LocalJobsDetail.getJobBasicInfo(_data['id']);
        data.forEach((k, v) => _data[k] = v);
      }

      if (_jobStatus[LocalJobsStatus.detail]) {
        final data = await LocalJobsDetail.getJobJobDetail(_data['id']);
        data.forEach((k, v) => _data[k] = v);
      }

      if (_data['job_detail'] == null) _data['job_detail'] = {};

      if (_data['job_status'] != submitted) _getLiveLocation();

      log("Server data $_data");

      LocalJobsDetail.saveJobDetailById(_data['id'], _data);

      log('C54: Response: $response');
      _pagerController.invalidatePage(_data);
    }

  }


  _loadLocalData() async {

    final response = await LocalJobsDetail.getJobDetailById(_data['id']) as Map;

    response.forEach((k, v) => _data[k] = v);

    if (response.isEmpty) {
      LocalJobsDetail.saveJobDetailById(_data['id'], _data);
    }

    if (_data['job_status'] != submitted) _getLiveLocation();

    log("Local data $_data");

    _pagerController.invalidatePage(_data);
  }


  get _updateUi => setState(() {});

  @override
  Widget build(BuildContext context) {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);

    final value = MediaQuery.of(context).viewInsets.bottom;
    if (value > 0) _pagerController.invalidateScrollListeners(value);

    return WillPopScope(
      onWillPop: () async {
        ++_backTapCount;
        Future.delayed(const Duration(milliseconds: 1000)).then((_) {
          if (_backTapCount >= 2) return;
          ASnackBar.showWarning(
            scaffoldMessengerState,
            'Please double click on back button to close this form',
          );
          _backTapCount = 0;
        });

        return _backTapCount > 1;
      },
      child: (_tabController == null)
          ? const SizedBox.shrink()
          : Pager(
              '#${_data['id'].isNegative ? 'NEW' : _data['id']}, Regn No. :${_data['vehicle_reg_no']}',
              tabs: (_data['platform'] == platformTypeMS)
                  ? [
                      _TabHeader('Upload Images', _activeIndex == 0),
                      _TabHeader('Survey Details', _activeIndex == 1),
                    ]
                  : [
                      _TabHeader('Basic Info', _activeIndex == 0),
                      _TabHeader('Vehicle  Details', _activeIndex == 1),
                      _TabHeader('Technical Features', _activeIndex == 2),
                    ],
              tabView: (_data['platform'] == platformTypeMS)
                  ? [
                      MSUploadImages(_pagerController),
                      MSSurveyDetails(_pagerController),
                    ]
                  : [
                      MVBasicInfo(_pagerController),
                      MVVehicleDetails(_pagerController),
                      MVTechnicalFeature(_pagerController),
                    ],
              tabController: _tabController,
              pagerController: _pagerController,
              showButton: _data['job_status'] == pending,
            ),
    );
  }
}


class _TabHeader extends StatelessWidget {

  final String title;
  final bool active;

  const _TabHeader(this.title, this.active, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AText(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: active ? Colors.black54 : Colors.black,
      ),
    );
  }
}


class PagerController {
  final _pagerListener = '_pagerListenerKey';
  final Map<String, void Function(dynamic)> _listener = {};
  final _idListener = {};
  final _clickListener = {};
  final _scrollListener = {};
  Future Function()? _createJob;

  dynamic _response;
  int? _idResponse;
  int _currentPageKey = 0;
  bool _currentPageButtonLoading = false;

  int get pageIndex => _currentPageKey;

  get buttonLoading => _currentPageButtonLoading;

  /// when page switch change page
  setCurrentPage(int currentPageKey) {
    _currentPageKey = currentPageKey;
  }

  /// button state change
  setButtonProgress(bool currentPageButtonLoading) {
    _currentPageButtonLoading = currentPageButtonLoading;
    navigate(-1);
  }

  /// add pager listener when page switch
  addListener(void Function(int moveTo) listener) {
    _listener[_pagerListener] = (v) {
      listener(v);
    };
  }

  /// response listener
  addResponseListener(String key, void Function(dynamic response) listener) {
    _listener[key] = listener;
    if (_response == null) return;
    listener.call(_response);
  }

  /// Add Main Button Listener
  addButtonListener(int key, Function() clickListener) {
    _clickListener[key] = clickListener;
  }

  /// Add scroll listener when we need to scroll to end
  addScrollListener(String key, Function(double value) listener) {
    _scrollListener[key] = listener;
  }

  ///
  invalidateScrollListeners(value) {
    for (var key in _scrollListener.keys) {
      _scrollListener[key]?.call(value);
    }
  }

  /// Button Click Handle
  onButtonClick() {
    _clickListener[_currentPageKey]?.call();
  }

  /// Changing pages
  /// -1 only for refresh page
  navigate(int navigateTo) {
    _currentPageButtonLoading =
        navigateTo == -1 ? _currentPageButtonLoading : false;
    _listener[_pagerListener]?.call(navigateTo);
  }

  /// Change in pager pages when response receive
  invalidatePage(response) {
    _response = response;
    for (var key in _listener.keys) {
      if (key == _pagerListener) continue;
      var fn = _listener[key];
      fn!(response);
      log('C71: invalidatePage: $key : $fn');
    }
  }

  /// Create Job If Can Aur Need
  createJob() async {
    final response = await _createJob?.call();
    _idResponse = response;
    if (_idResponse != null) _invalidateId(_idResponse!);
  }

  addJobCreateFunction(Future Function() createJob) {
    _createJob = createJob;
  }

  /// Id Listener
  addIdListener(String key, Function(int id) listener) {
    _idListener[key] = listener;
    if (_idResponse != null) listener.call(_idResponse!);
  }

  ///
  _invalidateId(int id) {
    _idListener.forEach((k, v) => v?.call(id));
  }
}