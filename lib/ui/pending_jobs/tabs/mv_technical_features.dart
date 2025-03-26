import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/ui/pending_jobs/pending_jobs.dart';
import 'package:moval/ui/pending_jobs/widget/location_warning.dart';
import 'package:moval/ui/pending_jobs/widget/submit_confirmation.dart';
import 'package:moval/ui/pending_jobs/widget/submit_success.dart';
import 'package:moval/ui/signature.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/util/location_controller.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/util/routes.dart';
import 'package:moval/widget/a_radio.dart';
import 'package:moval/widget/a_text.dart';
import 'package:moval/widget/edit_text.dart';
import '../../../api/api.dart';
import '../../../api/urls.dart';
import '../../../widget/a_snackbar.dart';

class MVTechnicalFeature extends StatefulWidget {
  final PagerController _pagerController;

  const MVTechnicalFeature(this._pagerController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<MVTechnicalFeature>
    with AutomaticKeepAliveClientMixin<MVTechnicalFeature> {
  final Map _data = {};
  final RadioController _radioController = RadioController();
  final EditTextController _editTextController = EditTextController();
  final ScrollController _scrollController = ScrollController();
  late Container _imageWidget = Container(
    color: Colors.grey[300],
    height: 0,
    child: const SizedBox(),
  );

  @override
  void initState() {
    _initiatePage();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)]),
              child: Column(
                children: [
                  ARadio(
                    'Engine & Transmission',
                    'engine_transmission',
                    _jobDetail,
                    const ['Running condition', 'Not in Running condition'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Electrical gadgets',
                    'electrical_gadgets',
                    _jobDetail,
                    const [
                      'Good & operative condition',
                      'Not in Running condition'
                    ],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Right Side',
                    'right_side',
                    _jobDetail,
                    const ['Satisfactory', 'Unsatisfactory'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Left Body',
                    'left_body',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Front Body',
                    'front_body',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Back Body',
                    'back_body',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Load Body',
                    'load_body',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'All Glass Condition',
                    'all_glass_condition',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Cabin Condition',
                    'cabin_condition',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Head Lamps/Back Lamps',
                    'head_lamp',
                    _jobDetail,
                    const ['Safe', 'Unsafe'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Tyres Condition',
                    'tyres_condition',
                    _jobDetail,
                    const ['Average', 'Good'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                  ARadio(
                    'Maintenance & Upkeep',
                    'maintenance',
                    _jobDetail,
                    const ['Satisfactory ', 'Unsatisfactory'],
                    controller: _radioController,
                    byIndex: true,
                  ),
                ],
              ),
            ),
            const AText(
              "Other Damages / Other special remarks",
              fontWeight: FontWeight.w500,
              margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
            ),
            EditText(
              "Write here...",
              'other_damages',
              _jobDetail,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              lines: 2,
              enableShadow: true,
              controller: _editTextController,
            ),
            Center(
              child: _imageWidget,
            ),
          ],
        ),
      ),
    );
  }

  _funOnSubmitted() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    if (widget._pagerController.buttonLoading) return;

    FocusScope.of(context).requestFocus(FocusNode());

    if (_getRadioData('engine_transmission').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Engine Transmission", 0);
      return;
    } else if (_getRadioData('electrical_gadgets').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Enter Electrical Gadgets", 0);
      return;
    } else if (_getRadioData('right_side').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Right Side", 0);
      return;
    } else if (_getRadioData('left_body').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Left Side", 0);
      return;
    } else if (_getRadioData('front_body').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Front Body", 0);
      return;
    } else if (_getRadioData('back_body').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Back Body", 0);
      return;
    } else if (_getRadioData('load_body').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Load Body", 0);
      return;
    } else if (_getRadioData('all_glass_condition').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select All Glass Condition", 0);
      return;
    } else if (_getRadioData('cabin_condition').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Cabin Condition", 0);
      return;
    } else if (_getRadioData('head_lamp').isNegative) {
      ASnackBar.showSnackBar(scaffoldMessengerState, "Please Select Lamps", 0);
      return;
    } else if (_getRadioData('tyres_condition').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Tyres Condition", 0);
      return;
    } else if (_getRadioData('maintenance').isNegative) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please Select Maintenance", 0);
      return;
    } else if (_getData('other_damages').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, "Please enter Other damage", 0);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Signature(
                  _data['id'],
                  platform: platformTypeMV,
                ))).then((value) async {
      if (value != null) {
        log(value[1]);
        setState(() {
          _imageWidget = Container(
            margin: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent),
                color: Colors.white),
            height: 100,
            alignment: Alignment.center,
            child: Image.memory(value[0]!.buffer.asUint8List()),
          );
          // _imageWidget = Container(
          //   color: Colors.grey[300],
          //   height: 100,
          //   child: Image.memory(value[0]!.buffer.asUint8List()),
          // );
        });

        final dialogResponse = await showDialog(
            context: context,
            builder: (builder) => const SubmitConfimationDialog());

        if (dialogResponse == null) return;

        widget._pagerController.setButtonProgress(true);

        final jobStatus = await LocalJobsStatus.getJobStatus(_data['id']);

        if (_data['id'].isNegative || jobStatus[LocalJobsStatus.basicInfo]) {
          _onSuccessfullyUpdate(true);
          widget._pagerController.setButtonProgress(false);
          return;
        }

        if (await Api.networkAvailable() &&
            _getData('is_offline') == 'no' &&
            _data['job_status'] != submitted) {
          final distance = Geolocator.distanceBetween(
              LocationController.position?.latitude ?? 0.0,
              LocationController.position?.longitude ?? 0.0,
              jobStatus[LocalJobsStatus.latitude],
              jobStatus[LocalJobsStatus.longitude]);

          int distance0 = 100;

          try {
            distance0 = int.parse('${_data['job_distance_filter']}');
          } catch (e) {
            log("-_-_____ ${e.toString()}}");
          }

          if (distance > distance0) {
            showDialog(
                context: context,
                builder: (builder) => const LocationWarning());
            widget._pagerController.setButtonProgress(false);
            return;
          }
        }

        _jobDetail['detail_type'] = technicalFeatures;
        _jobDetail['vehicle_owner_signature'] = value[1];
        final response = await Api(scaffoldMessengerState)
            .submitJobDetail(_data['id'], _jobDetail);

        if (response.runtimeType == String &&
            response.startsWith(Api.defaultError)) {
          ASnackBar.showError(scaffoldMessengerState, response);
        } else if (response == Api.internetError) {
          _onSuccessfullyUpdate(true);
        } else if (response == Api.authError) {
          UiUtils.authFailed(navigatorState);
        } else {
          _onSuccessfullyUpdate(false);
        }
        widget._pagerController.setButtonProgress(false);
      }
    });
  }

  _onSuccessfullyUpdate(bool isOffline) async {
    NavigatorState navigatorState = Navigator.of(context);
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.detail, isOffline);
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.checkLocation, !isOffline);

    if (!isOffline) {
      LocalJobsDetail.updateJobBasicInfo(
          _data['id'], {'job_status': submitted});
    }

    _localSaveJobVehicleDetail;

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (builder) => SubmitSuccess(_data['id'], isOffline));

    if (Preference.getBool(Preference.isGuest)) {
      Preference.setValue(Preference.isLogin, false);
      navigatorState.pushReplacementNamed(Routes.login);
    } else {
      navigatorState.pop('submitted');
    }
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    _radioController.addListener(
        RadioController.saveToLocalKey, () => _localSaveJobVehicleDetail);
    widget._pagerController
        .addResponseListener(technicalFeatures, _funOnResponse);
    widget._pagerController.addButtonListener(2, _funOnSubmitted);
    widget._pagerController
        .addScrollListener(technicalFeatures, _scrollListener);
    widget._pagerController
        .addIdListener(technicalFeatures, (id) => _data['id'] = id);
  }

  _scrollListener(double value) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
  }

  _funOnResponse(response) async {
    if (response == Api.defaultError) {
    } else {
      response.forEach((k, v) => _data[k] = v);

      await Future.delayed(const Duration(seconds: 1));
      _radioController.invalidateAll();
      _editTextController.invalidate('other_damages');
    }

    _updateUi;
  }

  int _getRadioData(String key) {
    return int.parse(_jobDetail[key] ?? '-1');
  }

  String _getData(String key) {
    return _jobDetail[key] ?? '';
  }

  get _updateUi => setState(() {});

  get _jobDetail => _data.putIfAbsent('job_detail', () => {});

  get _localSaveJobVehicleDetail =>
      LocalJobsDetail.updateJobVehicleDetail(_data['id'], _jobDetail);
}
