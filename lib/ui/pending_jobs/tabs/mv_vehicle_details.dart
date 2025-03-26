import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/local/local_vehicle_details.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/widget/a_radio.dart';
import 'package:moval/widget/date_selector.dart';
import 'package:moval/widget/edit_text.dart';
import 'package:moval/widget/search_drop_down.dart';

import '../../../api/api.dart';
import '../../../api/urls.dart';
import '../../../widget/a_snackbar.dart';
import '../pending_jobs.dart';

class MVVehicleDetails extends StatefulWidget {
  final PagerController _pagerController;

  const MVVehicleDetails(this._pagerController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<MVVehicleDetails>
    with AutomaticKeepAliveClientMixin<MVVehicleDetails> {
  final Map<String, dynamic> _data = {};
  final Map<String, dynamic> _constantVehicleDetail = {};
  final EditTextController _editTextController = EditTextController();
  final SearchDropDownController _searchDropDownController =
      SearchDropDownController();
  final RadioController _radioController = RadioController();
  final DateController _dateController = DateController();
  final ScrollController _scrollController = ScrollController();

  final regExp = RegExp(r'^[a-zA-Z0-9_/]+$');
  final regExp2 = RegExp(r'^[a-zA-Z0-9.\s]+$');
  final fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Others'];

  @override
  void initState() {
    _initiatePage();
    super.initState();
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
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  50,
                ),
                margin: const EdgeInsets.only(
                  top: 20,
                ),
                decoration:
                    const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black26,
                  )
                ]),
                child: Column(
                  children: [
                    SearchDropDown(
                      'Vehicle Class',
                      'vehicle_class',
                      _jobDetail,
                      _vehicleClass,
                      controller: _searchDropDownController,
                    ),
                    DateSelector(
                      'Enter Date of Registration',
                      'registration_date',
                      _jobDetail,
                      maxYear: DateTime.now().year + 1,
                      controller: _dateController,
                    ),
                    SearchDropDown(
                      'Enter type of Body',
                      'type_of_body',
                      _jobDetail,
                      _vehicleBodyType,
                      controller: _searchDropDownController,
                    ),
                    SearchDropDown(
                      'Manufacturing year',
                      'manufactoring_year',
                      _jobDetail,
                      _manufacturingYear,
                      controller: _searchDropDownController,
                      manualEnter: false,
                    ),
                    SearchDropDown(
                      'Maker',
                      'maker',
                      _jobDetail,
                      _vehicleMaker,
                      controller: _searchDropDownController,
                    ),
                    SearchDropDown(
                      'Model/Variant',
                      'model',
                      _jobDetail,
                      _vehicleVariants,
                      controller: _searchDropDownController,
                    ),
                    EditText(
                      'Chassis No.',
                      'chassis_no',
                      _jobDetail,
                      controller: _editTextController,
                    ),
                    EditText(
                      'Engine No.',
                      'engine_no',
                      _jobDetail,
                      controller: _editTextController,
                    ),
                    ARadio(
                      'RC Status',
                      'rc_status',
                      _jobDetail,
                      const ['Active', 'Inactive'],
                      horizontal: false,
                      controller: _radioController,
                      byIndex: true,
                    ),
                    EditText(
                      'Seating Capacity',
                      'seating_capacity',
                      _jobDetail,
                      number: true,
                      controller: _editTextController,
                      limit: 1,
                    ),
                    SearchDropDown(
                      'Issuing Authority',
                      'issuing_authority',
                      _jobDetail,
                      _vehicleIssueAuthority,
                      controller: _searchDropDownController,
                    ),
                    ARadio(
                      'Fuel',
                      'fuel_type_',
                      _jobDetail,
                      fuelTypes,
                      horizontal: true,
                      controller: _radioController,
                    ),
                    if (_getJobDetail('fuel_type_') == 'Others')
                      EditText(
                        'Fuel Other Type',
                        'fuel_type',
                        _jobDetail,
                        controller: _editTextController,
                      ),
                    SearchDropDown(
                      'Colour',
                      'color',
                      _jobDetail,
                      _vehicleColor,
                      controller: _searchDropDownController,
                    ),
                    EditText(
                      'Odometer Reading',
                      'odometer_reading',
                      _jobDetail,
                      controller: _editTextController,
                    ),
                    DateSelector(
                      'Fitness Valid Upto',
                      'fitness_valid_upto',
                      _jobDetail,
                      controller: _dateController,
                    ),
                    EditText(
                      'Laden Weight/kg',
                      'laden_weight',
                      _jobDetail,
                      controller: _editTextController,
                    ),
                    EditText(
                      'Unladen Weight/kg',
                      'unladen_weight',
                      _jobDetail,
                      controller: _editTextController,
                    ),
                    EditText(
                      'Vehicle Value',
                      'requested_value',
                      _jobDetail,
                      number: true,
                      onSubmitted: _next,
                      controller: _editTextController,
                      limit: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 140,
              ),
            ],
          )),
    );
  }

  _next() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    if (widget._pagerController.buttonLoading) return;

    FocusScope.of(context).requestFocus(FocusNode());

    if (_getJobDetail('chassis_no').isNotEmpty &&
        !regExp.hasMatch(_getJobDetail('chassis_no'))) {
      ASnackBar.showSnackBar(scaffoldMessengerState,
          'Only Alpha numeric value, _ and / are allowed in Chassis No', 0);
      return;
    } else if (_getJobDetail('engine_no').isNotEmpty &&
        !regExp.hasMatch(_getJobDetail('engine_no')!)) {
      ASnackBar.showSnackBar(scaffoldMessengerState,
          'Only Alpha numeric value, _ and / are allowed in Engine No', 0);
      return;
    } else if (_getJobDetail('odometer_reading').isNotEmpty &&
        !regExp2.hasMatch(_getJobDetail('odometer_reading'))) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Enter Valid Odometer Reading', 0);
      return;
    } else if (_getJobDetail('laden_weight').isNotEmpty &&
        !regExp2.hasMatch(_getJobDetail('laden_weight'))) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Enter Valid Laden Weight', 0);
      return;
    } else if (_getJobDetail('unladen_weight').isNotEmpty &&
        !regExp2.hasMatch(_getJobDetail('unladen_weight'))) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Enter Valid Unladen Weight', 0);
      return;
    } else if (_getJobDetail('requested_value').isNotEmpty &&
        !regExp2.hasMatch(_getJobDetail('requested_value'))) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Enter Valid Vehicle Value', 0);
      return;
    } else if (_getJobDetail('maker').isEmpty &&
        _getJobDetail('model').isNotEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Please select maker', 0);
      return;
    }

    widget._pagerController.setButtonProgress(true);

    _jobDetail['detail_type'] = vehicleDetail;
    if (_getJobDetail('rc_status') == '-1') _jobDetail['rc_status'] = '';

    if (_data['id'].isNegative ||
        await LocalJobsStatus.getJobStatusIsOffline(
            _data['id'], LocalJobsStatus.basicInfo)) {
      _onJobSubmit(true);
      return;
    }

    final response = await Api(scaffoldMessengerState)
        .submitJobDetail(_data['id'], _jobDetail);

    if (response == Api.defaultError) {
      _onJobSubmit(false);
    } else if (response == Api.internetError) {
      _onJobSubmit(true);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _onJobSubmit(false);
    }
  }

  _onJobSubmit(bool isOffline) async {
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.detail, isOffline);
    _localSaveJobVehicleDetail;
    await Future.delayed(const Duration(seconds: 1));
    widget._pagerController.navigate(2);
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    widget._pagerController.addResponseListener(vehicleDetail, _onResponse);
    widget._pagerController.addButtonListener(1, _next);
    widget._pagerController
        .addIdListener(vehicleDetail, (id) => _data['id'] = id);
    _searchDropDownController.addHandler(_searchDropDownHandler);
    _searchDropDownController.addScrollListener(_searchDropDownScrollListener);
    _radioController.addHandler(_radioButtonHandler);
    _getVehicleConstantData();
  }

  _searchDropDownScrollListener(double value) {
    final position = _scrollController.offset;
    _scrollController.animateTo(position - value,
        duration: const Duration(milliseconds: 75), curve: Curves.linear);
  }

  ///
  /// Job Details Response
  ///
  _onResponse(response) async {
    log("at Vehicle Detail $response");

    await Future.delayed(const Duration(milliseconds: 75));
    if (response == Api.defaultError) {
    } else {
      response.forEach((k, v) => _data[k] = v);
      String fuelType = _getJobDetail('fuel_type');
      _jobDetail['fuel_type_'] = fuelTypes.contains(fuelType)
          ? fuelType
          : fuelType.isNotEmpty
              ? 'Others'
              : '';
      _updateUi;
      await Future.delayed(const Duration(seconds: 1));
      _radioController.invalidateAll();
      _searchDropDownController.invalidateAll('updateValue');
      _editTextController.invalidateAll();
      _dateController.invalidateAll();
    }
  }

  ///
  /// Vehicle Details Constant
  ///
  _getVehicleConstantData() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getVehicleConstantData();

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _getLocalVehicleConstantData();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      response.forEach((k, v) => _constantVehicleDetail[k] = v);

      LocalVehicleDetails.saveVehicleDetails(_constantVehicleDetail);
      _constantVehicleDetail['manufacturingYear'] = _getManufacturingYear();
      _updateUi;
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidateAll(Api.success);
    }
  }

  _getLocalVehicleConstantData() async {
    final response = await LocalVehicleDetails.getVehicleDetails();

    response.forEach((k, v) => _constantVehicleDetail[k] = v);

    _constantVehicleDetail['manufacturingYear'] = _getManufacturingYear();
    _updateUi;
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidateAll(Api.success);
  }

  ///
  /// Vehicle variants
  ///
  _getVehicleVariants(int? makerId) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    _searchDropDownController.invalidate('model', Api.loading);

    if (makerId == null) {
      _searchDropDownController.invalidate('model', Api.success);
      return;
    }

    final response =
        await Api(scaffoldMessengerState).getVehicleVariantList(makerId);

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _getLocalVehicleVariants(makerId);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _constantVehicleDetail['vehicle_variants'] = response;
      LocalVehicleVariants.saveVehicleVariant(makerId, response);
    }
    _updateUi;
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidate('model', Api.success);
  }

  ///
  /// Local Vehicle Variants
  ///
  _getLocalVehicleVariants(int makerId) async {
    _searchDropDownController.invalidate('model', Api.loading);
    final response = await LocalVehicleVariants.getVehicleVariant(makerId);
    _constantVehicleDetail['vehicle_variants'] = response;
    _updateUi;
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidate('model', Api.success);
  }

  _searchDropDownHandler(String k, dynamic v) {
    switch (k) {
      case 'maker':
        _getVehicleVariants(v == null ? null : v['id']);
        break;
      case 'model':
        if (v != null && v.runtimeType != String) {
          _jobDetail['seating_capacity'] = v['seats'];
          _editTextController.invalidate('seating_capacity');
        }
        break;
    }
  }

  _radioButtonHandler(String k, dynamic v) {
    if (k == 'fuel_type_') {
      _jobDetail['fuel_type'] = v == 'Others' ? '' : v;
      _updateUi;
    }
  }

  _getManufacturingYear() {
    final List years = [];
    for (int a = DateTime.now().year; a >= 1900; a--) {
      years.add({'name': '$a'});
    }
    return years;
  }

  _getJobDetail(String key) => (_jobDetail[key] ?? '').toString();

  get _updateUi => setState(() {});

  get _vehicleClass =>
      _constantVehicleDetail.putIfAbsent('vehicle_class', () => []);

  get _vehicleColor =>
      _constantVehicleDetail.putIfAbsent('vehicle_colors', () => []);

  get _vehicleBodyType =>
      _constantVehicleDetail.putIfAbsent('vehicle_body_type', () => []);

  get _vehicleMaker =>
      _constantVehicleDetail.putIfAbsent('vehicle_makers', () => []);

  get _vehicleIssueAuthority =>
      _constantVehicleDetail.putIfAbsent('vehicle_issue_authority', () => []);

  get _vehicleVariants =>
      _constantVehicleDetail.putIfAbsent('vehicle_variants', () => []);

  get _manufacturingYear =>
      _constantVehicleDetail.putIfAbsent('manufacturingYear', () => []);

  get _localSaveJobVehicleDetail =>
      LocalJobsDetail.updateJobVehicleDetail(_data['id'], _jobDetail);

  get _jobDetail => _data.putIfAbsent('job_detail', () => {});
}
