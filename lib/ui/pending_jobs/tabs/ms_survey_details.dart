import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/widget/date_selector.dart';
import 'package:moval/widget/edit_text.dart';
import 'package:moval/widget/search_drop_down.dart';
import '../../../api/api.dart';
import '../../../api/urls.dart';
import '../../../local/local_branch_list.dart';
import '../../../util/location_controller.dart';
import '../../../util/preference.dart';
import '../../../util/routes.dart';
import '../../../widget/a_snackbar.dart';
import '../../../widget/a_text.dart';
import '../../../widget/date_selector.dart' as ds;
import '../../signature.dart';
import '../pending_jobs.dart';
import '../widget/location_warning.dart';
import '../widget/submit_confirmation.dart';
import '../widget/submit_success.dart';

class MSSurveyDetails extends StatefulWidget {
  final PagerController _pagerController;

  const MSSurveyDetails(this._pagerController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<MSSurveyDetails>
    with AutomaticKeepAliveClientMixin<MSSurveyDetails> {
  final ScrollController _scrollController = ScrollController();
  final SearchDropDownController _searchDropDownController =
      SearchDropDownController();
  final EditTextController _editTextController = EditTextController();
  final DateController _dateController = DateController();
  final Map<String, dynamic> _data = {};
  Uint8List? _signatureImageData;
  final List _claimTypeList = [
    {
      'id': '1',
      'name': 'Final Survey',
    },
    {
      'id': '2',
      'name': 'Spot Survey',
    },
  ];
  final List _branchList = [];
  final List _clientList = [];
  final List _clientBranchList = [];
  final List _sopList = [];
  final List _workshopList = [];
  final List _workshopBranchList = [];
  final bool _sameAsWorkshop = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initiatePage();
    });
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    widget._pagerController.addResponseListener(vehicleDetail, _onResponse);
    widget._pagerController.addButtonListener(1, _next);
    widget._pagerController
        .addIdListener(vehicleDetail, (id) => _data['id'] = id);
    _searchDropDownController.addHandler(_searchDropDownHandler);
    _searchDropDownController.addScrollListener(_searchDropDownScrollListener);
  }

  Future<void> _getBranchList() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    int userId = Preference.getInt(Preference.userId);
    int userParentId = Preference.getInt(Preference.userParentId);
    final response = await Api(scaffoldMessengerState).getBranchList(
      adminId: (userParentId == -1) ? userId : userParentId,
    );

    log(response.toString());

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      await _getLocalBranchList();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      final data = response['values'] ?? [];
      LocalBranchList.saveAllBranch(data);
      _branchList.addAll(data);
    }
    _updateUi;
  }

  Future<void> _getLocalBranchList() async {
    final response = await LocalBranchList.getAllBranch();
    _branchList.addAll(response);
  }

  Future<void> _getClientList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
    ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getClientList(
      platform: platformTypeMS,
      branchId: branchId,
    );

    log(response.toString());

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _clientList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getClientBranchList({required int clientId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
    ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getClientBranchList(
      clientId: clientId,
    );

    log(response.toString());

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _clientBranchList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getSopList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
    ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getSopList(
      branchId: branchId,
    );

    log(response.toString());

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _sopList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getWorkshopList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
    ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getWorkshopList(
      branchId: branchId,
    );

    log(response.toString());

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _workshopList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getWorkshopBranchList({required int workshopId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
    ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getWorkshopBranchList(
      workshopId: workshopId,
    );

    log(response.toString());

    if (response == Api.defaultError || response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _workshopBranchList.addAll(response);
    }
    _updateUi;
  }

  _searchDropDownHandler(String k, dynamic v) async {
    if (k == 'selected_branch') {
      await _onSelectedBranch(v);
      _updateUi;
      return;
    }

    if (k == 'workshop_name') {
      await _onSelectedWorkshop(v);
      _updateUi;
      return;
    }

    if (k == 'selected_office_code') {
      await _onSelectedOfficeCode(v);
      _updateUi;
      return;
    }

    if (k == 'selected_client') {
      await _onSelectedClient(v);
      _updateUi;
      return;
    }
  }

  Future<void> _onSelectedOfficeCode(dynamic v) async {
    _data['office_name'] = v['office_name'] ?? '';
    _editTextController.invalidate('office_name');

    _data['office_address'] = v['office_address'] ?? '';
    _editTextController.invalidate('office_address');
  }

  Future<void> _onSelectedBranch(dynamic v) async {
    _searchDropDownController.invalidate('workHob Noshop_name', Api.loading);
    _searchDropDownController.invalidate('selected_sop', Api.loading);
    _searchDropDownController.invalidate('selected_client', Api.loading);

    int branchId = v['id'];
    _workshopList.clear();
    await _getWorkshopList(branchId: branchId);

    _clientList.clear();
    await _getClientList(branchId: branchId);

    _sopList.clear();
    await _getSopList(branchId: branchId);

    _searchDropDownController.invalidate('workshop_name', Api.success);
    _searchDropDownController.invalidate('selected_sop', Api.success);
    _searchDropDownController.invalidate('selected_client', Api.success);
  }

  Future<void> _onSelectedClient(dynamic v) async {
    _searchDropDownController.invalidate('selected_office_code', Api.loading);

    int clientId = v['id'];
    _clientBranchList.clear();
    await _getClientBranchList(clientId: clientId);

    _searchDropDownController.invalidate('selected_office_code', Api.success);
  }

  Future<void> _onSelectedWorkshop(dynamic v) async {
    if(_sameAsWorkshop) {
      _data['place_of_survey'] = _data['workshop_name'];
      _editTextController.invalidate('place_of_survey');
      _updateUi;
    }

    _searchDropDownController.invalidate('workshop_branch', Api.loading);

    int workshopId = v['id'];
    _workshopBranchList.clear();
    await _getWorkshopBranchList(workshopId: workshopId);

    _searchDropDownController.invalidate('workshop_branch', Api.success);
  }

  _onResponse(response) async {
    log("at Survey Detail: $response");
    if (response == Api.defaultError) {
      return;
    }
    await _getBranchList();
    final selectedBranch = _branchList.firstWhere(
        (e) => e['id'].toString() == response['admin_branch_id'].toString(),
        orElse: () => {'branch_name': ''});

    int branchId = (response['admin_branch_id'] is int)
        ? response['admin_branch_id']
        : int.tryParse(response['admin_branch_id']) ?? -1;
    await _getWorkshopList(branchId: branchId);

    await _getClientList(branchId: branchId);

    await _getSopList(branchId: branchId);

    int clientId = response['client_id'];
    await _getClientBranchList(clientId: clientId);
    final selectedClientBranch = _clientBranchList.firstWhere(
        (e) => e['id'] == response['client_branch_id'],
        orElse: () => {'office_code': ''});

    int workshopId = response['workshop_id'];
    await _getWorkshopBranchList(workshopId: workshopId);

    _data.addAll({
      ...response,
      'claim_type': _claimTypeList.firstWhere(
          (e) => e['id'] == response['claim_type'],
          orElse: () => {'name': ''})['name'],
      'place_of_survey': response['place_survey'],
      'workshop_name': _workshopList.firstWhere(
          (e) => e['id'] == response['workshop_id'],
          orElse: () => {'workshop_name': ''})['workshop_name'],
      'workshop_branch': _workshopBranchList.firstWhere(
          (e) => e['id'] == response['workshop_branch_id'],
          orElse: () => {'workshop_branch_name': ''})['workshop_branch_name'],
      'contact_person_name': response['contact_person'],
      'contact_mobile_no': response['contact_no'],
      'selected_client': _clientList.firstWhere(
          (e) => e['id'] == response['client_id'],
          orElse: () => {'client_name': ''})['client_name'],
      'registration_date': response['date_of_appointment'],
      'selected_sop': _sopList.firstWhere((e) {
        String eId = e['id'].toString();
        String resSopId = response['sop_id'].toString();
        return eId == resSopId;
      }, orElse: () => {'sop_name': ''})['sop_name'],
      'selected_office_code': selectedClientBranch['office_code'],
      'office_name': selectedClientBranch['office_name'],
      'office_address': selectedClientBranch['office_address'],
      'selected_branch': selectedBranch['branch_name'],
    });
    _updateUi;

    _searchDropDownController.invalidateAll(Api.success);
    _searchDropDownController.invalidateAll('updateValue');
    _editTextController.invalidateAll();
    _dateController.invalidateAll();
  }

  _funOnSubmitted() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    FocusScope.of(context).requestFocus(FocusNode());

    final signatureData = await navigatorState.push(MaterialPageRoute(
        builder: (context) => Signature(
              _data['id'],
              platform: platformTypeMS,
            )));

    if (signatureData == null) {
      widget._pagerController.setButtonProgress(false);
      return;
    }

    log(signatureData[1]);
    setState(() {
      _signatureImageData = signatureData[0]!.buffer.asUint8List();
    });

    final dialogResponse = await showDialog(
        context: context,
        builder: (builder) => SubmitDataDialog());
    if (dialogResponse == null) {
      widget._pagerController.setButtonProgress(false);
      return;
    }

    widget._pagerController.setButtonProgress(true);

    final jobStatus = await LocalJobsStatus.getJobStatus(_data['id']);

    if (_data['id'].isNegative || jobStatus[LocalJobsStatus.basicInfo]) {
      _onSuccessfullyUpdate(true);
      widget._pagerController.setButtonProgress(false);
      return;
    }

    if (await Api.networkAvailable() &&
        (_data['job_detail']['is_offline'] ?? '') == 'no' &&
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
            context: context, builder: (builder) => const LocationWarning());
        widget._pagerController.setButtonProgress(false);
        return;
      }
    }

    final response = await Api(scaffoldMessengerState).submitMSJobSignature(
      jobId: _data['id'],
      signatureUrl: signatureData[1],
    );

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

  bool _validateForm(ScaffoldMessengerState state) {
    if (_getData('claim_type').isEmpty) {
      ASnackBar.showSnackBar(state, 'Claim Type Required', 0);
      return false;
    } else if (_getData('selected_branch').isEmpty) {
      ASnackBar.showSnackBar(state, 'Branch Required', 0);
      return false;
    } else if (_getData('vehicle_reg_no').isEmpty) {
      ASnackBar.showSnackBar(state, 'Vehicle Registration No Required', 0);
      return false;
    } else if (_getData('insured_name').isEmpty) {
      ASnackBar.showSnackBar(state, 'Insured Name Required', 0);
      return false;
    } else if (_getData('place_of_survey').isEmpty) {
      ASnackBar.showSnackBar(state, 'Place of Survey Required', 0);
      return false;
    } else if (_getData('workshop_name').isEmpty) {
      ASnackBar.showSnackBar(state, 'Workshop Name Required', 0);
      return false;
    } else if (_getData('workshop_branch').isEmpty) {
      ASnackBar.showSnackBar(state, 'Workshop Branch Required', 0);
      return false;
    } else if (_getData('contact_mobile_no').isEmpty) {
      ASnackBar.showSnackBar(state, 'Mobile Number Required', 0);
      return false;
    } else if (_getData('contact_person_name').isEmpty) {
      ASnackBar.showSnackBar(state, 'Contact Person Required', 0);
      return false;
    } else if (_getData('contact_mobile_no').length != 10) {
      ASnackBar.showSnackBar(state, 'Mobile Number must be 10 digits', 0);
      return false;
    } else if (_getData('selected_client').isEmpty) {
      ASnackBar.showSnackBar(state, 'Client Required', 0);
      return false;
    } else if (_getData('selected_office_code').isEmpty) {
      ASnackBar.showSnackBar(state, 'Office Code Required', 0);
      return false;
    } else if (_getData('registration_date').isEmpty) {
      ASnackBar.showSnackBar(state, 'Appointment Date Required', 0);
      return false;
    } else if (_getData('selected_sop').isEmpty) {
      ASnackBar.showSnackBar(state, 'Sop Required', 0);
      return false;
    }
    return true;
  }

  _next() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    if (widget._pagerController.buttonLoading) return;

    FocusScope.of(context).requestFocus(FocusNode());

    if (!_validateForm(scaffoldMessengerState)) return;

    widget._pagerController.setButtonProgress(true);

    if (_data['id'].isNegative ||
        await LocalJobsStatus.getJobStatusIsOffline(
            _data['id'], LocalJobsStatus.basicInfo)) {
      _onUpdateJobDetails(true);
      return;
    }

    final selectedBranch = _branchList.firstWhere(
            (e) => e['branch_name'] == _data['selected_branch'],
        orElse: () => {'id': -1});
    final selectedClientBranch = _clientBranchList.firstWhere(
            (e) => e['office_code'] == _data['selected_office_code'],
        orElse: () => {'id': -1});
    final response =
    await Api(scaffoldMessengerState).updateMSJobDetail(_data['id'], {
      'claim_type': _claimTypeList.firstWhere(
          (e) => e['name'] == _data['claim_type'],
          orElse: () => {'id': -1})['id'],
      'vehicle_reg_no': _data['vehicle_reg_no'],
      'insured_name': _data['insured_name'],
      'place_survey': _data['place_of_survey'],
      'workshop_id': _workshopList.firstWhere(
          (e) => e['workshop_name'] == _data['workshop_name'],
          orElse: () => {'id': -1})['id'],
      'workshop_branch_id': _workshopBranchList.firstWhere(
          (e) => e['workshop_branch_name'] == _data['workshop_branch'],
          orElse: () => {'id': -1})['id'],
      'contact_no': _data['contact_mobile_no'],
      'client_id': _clientList.firstWhere(
              (e) => e['name'] == _data['selected_client'],
          orElse: () => {'id': -1})['id'],
      'client_branch_id': selectedClientBranch['id'],
      'admin_branch_id': selectedBranch['id'],
      'date_time_appoinment': _data['registration_date'],
      'sop_id': _sopList.firstWhere(
              (e) => e['sop_name'] == _data['selected_sop'],
          orElse: () => {'id': -1})['id'],
      'branch_name': selectedBranch['branch_name'],
      'created_by': Preference.getInt(Preference.userId).toString(),
      'Job_Route_To': '1',
      'upload_type': '1',
    });

    if (response == Api.defaultError) {
      _onUpdateJobDetails(false);
    } else if (response == Api.internetError) {
      _onUpdateJobDetails(true);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _onUpdateJobDetails(false);
    }
  }

  _onUpdateJobDetails(bool isOffline) async {
    LocalJobsStatus.saveJobStatusIsOffline(
        _data['id'], LocalJobsStatus.detail, isOffline);
    _localSaveJobVehicleDetail;
    _funOnSubmitted();
  }

  _searchDropDownScrollListener(double value) {
    final position = _scrollController.offset;
    _scrollController.animateTo(position - value,
        duration: const Duration(milliseconds: 75), curve: Curves.linear);
  }

  get _localSaveJobVehicleDetail =>
      LocalJobsDetail.updateJobVehicleDetail(_data['id'], _data);

  get _updateUi {
    if (!mounted) return;
    setState(() {});
  }

  String _getData(String key) => (_data[key] ?? '').toString();

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 50,),
                margin: const EdgeInsets.only(top: 20,),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black26,
                      )
                    ]
                ),
                child: Column(
                  children: [
                    SearchDropDown(
                      'Enter Claim Type',
                      'claim_type',
                      _data,
                      _claimTypeList,
                      controller: _searchDropDownController,
                      optionKey: 'name',
                      manualEnter: false,
                      isEnabled: false,
                    ),
                    SearchDropDown(
                      'Select Branch',
                      'selected_branch',
                      _data,
                      _branchList,
                      controller: _searchDropDownController,
                      optionKey: 'branch_name',
                      manualEnter: false,
                      isEnabled: false,
                    ),
                    EditText(
                      'Enter Vehicle Registration No',
                      'vehicle_reg_no',
                      _data,
                      controller: _editTextController,
                      isEnable: false,
                    ),
                    EditText(
                      'Enter Insured Name',
                      'insured_name',
                      _data,
                      controller: _editTextController,
                      isTitleCase: true,
                      isEnable: false,
                    ),
                    EditText(
                      'Enter Place of Survey',
                      'place_of_survey',
                      _data,
                      controller: _editTextController,
                      isEnable: false,
                    ),
                    Row(
                      children: [
                        const AText(
                          'Same as Workshop: ',
                          fontWeight: FontWeight.w500,
                          margin: EdgeInsets.only(left: 10, bottom: 5),
                        ),
                        Switch(
                          value: _sameAsWorkshop,
                          onChanged: null,
                        ),
                      ],
                    ),
                    SearchDropDown(
                      'Enter Workshop Name',
                      'workshop_name',
                      _data,
                      _workshopList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                      optionKey: 'workshop_name',
                      isEnabled: false,
                    ),
                    SearchDropDown(
                      'Enter Workshop Branch',
                      'workshop_branch',
                      _data,
                      _workshopBranchList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                      optionKey: 'workshop_branch_name',
                      isEnabled: false,
                    ),
                    EditText(
                      'Contact Person',
                      'contact_person_name',
                      _data,
                      controller: _editTextController,
                      isEnable: false,
                    ),
                    EditText(
                      'Enter Contact Person Mobile No.',
                      'contact_mobile_no',
                      _data,
                      number: true,
                      controller: _editTextController,
                      isEnable: false,
                    ),
                    SearchDropDown(
                      'Select Client',
                      'selected_client',
                      _data,
                      _clientList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                      optionKey: 'name',
                      isEnabled: false,
                    ),
                    SearchDropDown(
                      'Select Office Code',
                      'selected_office_code',
                      _data,
                      _clientBranchList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                      optionKey: 'office_code',
                      isEnabled: false,
                    ),
                    EditText(
                      'Office Name',
                      'office_name',
                      _data,
                      isEnable: false,
                      controller: _editTextController,
                    ),
                    EditText(
                      'Office Address',
                      'office_address',
                      _data,
                      isEnable: false,
                      controller: _editTextController,
                    ),
                    ds.DateSelector(
                      'Enter Date of Appointment',
                      'registration_date',
                      _data,
                      maxYear: DateTime
                          .now()
                          .year + 1,
                      controller: _dateController,
                      visibleDateFormat: 'dd MMM yyyy',
                      savedDateFormat: 'yyyy-MM-dd',
                      isEnabled: false,
                    ),
                    SearchDropDown(
                      'Select SOP',
                      'selected_sop',
                      _data,
                      _sopList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                      optionKey: 'sop_name',
                      isEnabled: false,
                    ),
                    if (_signatureImageData != null)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.redAccent),
                              color: Colors.white),
                          height: 100,
                          alignment: Alignment.center,
                          child: Image.memory(_signatureImageData!),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          )
      ),
    );
  }
}
