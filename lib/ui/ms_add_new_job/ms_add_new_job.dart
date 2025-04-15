import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/ui/home_screen/home_view_ui.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/widget/header.dart';
import 'package:moval/widget/search_drop_down.dart';

import '../../api/api.dart';
import '../../local/local_branch_list.dart';
import '../../local/local_jobs.dart';
import '../../util/preference.dart';
import '../../widget/a_snackbar.dart';
import '../../widget/a_text.dart';
import '../../widget/button.dart';
import '../../widget/date_selector.dart' as ds;
import '../../widget/edit_text.dart';
import '../home_screen/home_screen_ui.dart';

class MSAddNewJob extends StatefulWidget{

  const MSAddNewJob({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddNewJob();
  }

}

class _AddNewJob extends State<MSAddNewJob> {

  final SearchDropDownController _searchDropDownController =
      SearchDropDownController();
  final ScrollController _scrollController = ScrollController();
  final ds.DateController _dateController = ds.DateController();
  final EditTextController _editTextController = EditTextController();
  final Map<String, dynamic> _data = {};
  final List _claimTypeList = [
    {
      'id': 1,
      'name': 'Final Survey',
    },
    {
      'id': 2,
      'name': 'Spot Survey',
    },
  ];
  final List _branchList = [];
  final List _clientList = [];
  final List _clientBranchList = [];
  final List _sopList = [];
  final List _workshopList = [];
  final List _workshopBranchList = [];
  bool _sameAsWorkshop = false;
  int _backTapCount = 0;
  bool _apiCalling = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initiatePage();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  get _body => SingleChildScrollView(
    controller: _scrollController,
    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AText(
            'Basic Information',
            textColor: Colors.black,
            fontWeight: FontWeight.w600,
            padding: EdgeInsets.only(left: 20, top: 20),
          ),
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
            decoration: UiUtils.decoration(),
            child: Column(
              children: [
                SearchDropDown(
                  'Enter Claim Type',
                  'claim_type',
                  _data,
                  _claimTypeList,
                  controller: _searchDropDownController,
                  optionKey: 'name',
                ),
                SearchDropDown(
                  'Select Branch',
                  'selected_branch',
                  _data,
                  _branchList,
                  controller: _searchDropDownController,
                  optionKey: 'branch_name',
                ),
                EditText(
                  'Enter Vehicle Registration No',
                  'vehicle_reg_no',
                  _data,
                ),
                EditText(
                  'Enter Insured Name',
                  'insured_name',
                  _data,
                  isTitleCase: true,
                ),
                EditText(
                  'Enter Place of Survey',
                  'place_of_survey',
                  _data,
                  controller: _editTextController,
                  isEnable: !_sameAsWorkshop,
                  onChanged: (value) {
                    // Force refresh UI when place_of_survey changes to update Same as Workshop visibility
                    setState(() {});
                  },
                ),
                // Only show the Same as Workshop option when place_of_survey is empty
                if (_getData('place_of_survey').isEmpty)
                  Row(
                    children: [
                      const AText(
                        'Same as Workshop: ',
                        fontWeight: FontWeight.w500,
                        margin: EdgeInsets.only(left: 10, bottom: 5),
                      ),
                      Switch(
                        value: _sameAsWorkshop,
                        onChanged: _onChangeSameAsWorkshop,
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
                ),
                SearchDropDown(
                  'Enter Workshop Branch',
                  'workshop_branch',
                  _data,
                  _workshopBranchList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                  optionKey: 'workshop_branch_name',
                ),
                EditText(
                  'Contact Person',
                  'contact_person_name',
                  _data,
                  controller: _editTextController,
                ),
                EditText(
                  'Enter Contact Person Mobile No.',
                  'contact_mobile_no',
                  _data,
                  number: true,
                  controller: _editTextController,
                ),
                SearchDropDown(
                  'Select Client',
                  'selected_client',
                  _data,
                  _clientList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                  optionKey: 'client_name',
                ),
                SearchDropDown(
                  'Select Office Code',
                  'selected_office_code',
                  _data,
                  _clientBranchList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                  optionKey: 'office_code',
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
                  maxYear: DateTime.now().year + 1,
                  controller: _dateController,
                  visibleDateFormat: 'dd MMM yyyy',
                  savedDateFormat: 'yyyy-MM-dd HH:mm',
                ),
                SearchDropDown(
                  'Select SOP',
                  'selected_sop',
                  _data,
                  _sopList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                  optionKey: 'sop_name',
                ),
              ],
            ),
          ),
          Button(
            'Add Claim',
            progress: _apiCalling,
            onTap: _onAddJob,
            margin: const EdgeInsets.fromLTRB(20, 65, 20, 35),
          ),
          //const SizedBox(height: 240,),
        ]),
  );


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessengerState scaffoldMessengerState =
            ScaffoldMessenger.of(context);
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
      child: HomeView(
        selectedTab: 2,
        addJob: 1,
        showAddBtn: false,
        child: Header(
          'Create New Claim',
          doublePressEnable: true,
          child: _body,
        ),
      ),
    );
  }

  void _initiatePage() async {
    _searchDropDownController.addHandler(_searchDropDownHandler);
    _searchDropDownController.addScrollListener(_searchDropDownScrollListener);

    await _getBranchList();

    _searchDropDownController.invalidateAll(Api.success);
    _dateController.invalidateAll();
  }

  void _searchDropDownHandler(String k, dynamic v) async {
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

    if (k == 'selected_client') {
      await _onSelectedClient(v);
      _updateUi;
      return;
    }

    if (k == 'selected_office_code') {
      await _onSelectedOfficeCode(v);
      _updateUi;
      return;
    }

    if (k == 'contact_person_name') {
      await _onSelectedContactPersonName(v);
      _updateUi;
      return;
    }
  }

  Future<void> _onSelectedBranch(dynamic v) async {
    _searchDropDownController.invalidate('workshop_name', Api.loading);
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

  Future<void> _onSelectedClient(dynamic v) async {
    _searchDropDownController.invalidate('selected_office_code', Api.loading);

    int clientId = v['id'];
    _clientBranchList.clear();
    await _getClientBranchList(clientId: clientId);

    _searchDropDownController.invalidate('selected_office_code', Api.success);
  }

  Future<void> _onSelectedOfficeCode(dynamic v) async {
    _data['office_name'] = v['office_name'] ?? '';
    _editTextController.invalidate('office_name');

    _data['office_address'] = v['office_address'] ?? '';
    _editTextController.invalidate('office_address');
  }

  Future<void> _onSelectedContactPersonName(dynamic v) async {
    _data['contact_mobile_no'] = v['mobile_no'];
    _editTextController.invalidate('contact_mobile_no');

    _updateUi;
  }

  Future<void> _onChangeSameAsWorkshop(bool v) async {
    _sameAsWorkshop = v;

    _data['place_of_survey'] = (v) ? _data['workshop_name'] : '';
    _editTextController.invalidate('place_of_survey');

    _updateUi;
  }

  void _searchDropDownScrollListener(double value) {}

  Future<void> _getBranchList() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getBranchList(
      adminId: Preference.getInt(Preference.userId),
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

    // Clear the previous list to ensure we don't have duplicates
    _clientBranchList.clear();
    
    // Set the dropdown to loading state while fetching data
    _searchDropDownController.invalidate('selected_office_code', Api.loading);

    final response = await Api(scaffoldMessengerState).getClientBranchList(
      clientId: clientId,
    );

    log("Client Branch List Response: $response");

    if (response == Api.defaultError || response == Api.internetError) {
      // Show error state in dropdown
      _searchDropDownController.invalidate('selected_office_code', Api.defaultError);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      // Extract the 'values' list from the response
      final List branchList = response is Map && response.containsKey('values') 
          ? response['values'] ?? []
          : (response is List ? response : []);
      
      if (branchList.isNotEmpty) {
        // Add all office codes to the client branch list
        _clientBranchList.addAll(branchList);
        
        // Clear any previously selected office code when changing client
        if (_data.containsKey('selected_office_code')) {
          _data['selected_office_code'] = '';
        }
        
        // Clear office name and address when changing client
        _data['office_name'] = '';
        _editTextController.invalidate('office_name');
        _data['office_address'] = '';
        _editTextController.invalidate('office_address');
        
        log("Added ${branchList.length} office codes to dropdown");
        
        // Set dropdown to success state
        _searchDropDownController.invalidate('selected_office_code', Api.success);
      } else {
        // If response is empty, show a message
        log("No office codes found in response");
        ASnackBar.showWarning(scaffoldMessengerState, 'No office codes found for this client');
        _searchDropDownController.invalidate('selected_office_code', Api.defaultError);
      }
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

  void _onAddJob() async {
    if (_apiCalling) return;

    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    FocusScope.of(context).requestFocus(FocusNode());

    if (_getData('claim_type').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Claim Type Required', 0);
      return;
    } else if (_getData('selected_branch').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Branch Required', 0);
      return;
    } else if (_getData('vehicle_reg_no').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Vehicle Registration No Required', 0);
      return;
    } else if (_getData('insured_name').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Insured Name Required', 0);
      return;
    } else if (_getData('place_of_survey').isEmpty && !_sameAsWorkshop) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Place of Survey Required', 0);
      return;
    } else if (_getData('workshop_name').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Workshop Name Required', 0);
      return;
    } else if (_getData('workshop_branch').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Workshop Branch Required', 0);
      return;
    } else if (_getData('contact_person_name').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Contact Person Required', 0);
      return;
    } else if (_getData('contact_mobile_no').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Mobile Number Required', 0);
      return;
    } else if (_getData('contact_mobile_no').length != 10) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Mobile Number must be 10 digits', 0);
      return;
    } else if (_getData('selected_client').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Client Required', 0);
      return;
    } else if (_getData('selected_office_code').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Office Code Required', 0);
      return;
    } else if (_getData('registration_date').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Appointment Date Required', 0);
      return;
    } else if (_getData('selected_sop').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Sop Required', 0);
      return;
    }

    _apiCalling = true;
    _updateUi;

    final selectedBranch = _branchList.firstWhere(
        (e) => e['branch_name'] == _data['selected_branch'],
        orElse: () => {'id': -1});
    final selectedClientBranch = _clientBranchList.firstWhere(
        (e) => e['office_code'] == _data['selected_office_code'],
        orElse: () => {'id': -1});
    final response = await Api(scaffoldMessengerState).createMSJob({
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
              (e) => e['client_name'] == _data['selected_client'],
          orElse: () => {'id': -1})['id'],
      'client_branch_id': selectedClientBranch['id'],
      'admin_branch_id': selectedBranch['id'],
      'date_of_appointment': _data['registration_date'],
      'sop_id': _sopList.firstWhere(
          (e) => e['sop_name'] == _data['selected_sop'],
          orElse: () => {'id': -1})['id'],
      'branch_name': selectedBranch['branch_name'],
      'created_by': Preference.getInt(Preference.userId).toString(),
      'contact_person': _getData('contact_person_name'),
      'same_as_workshop': _sameAsWorkshop ? '1' : '0',
      'Job_Route_To': '1',
      'upload_type': '1',
    });
    _apiCalling = false;
    _updateUi;

    if (response.runtimeType == String &&
        response.startsWith(Api.defaultError)) {
      ASnackBar.showError(scaffoldMessengerState, response);
      return;
    } else if (response == Api.internetError) {
      _saveJob(true);
      return;
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
      return;
    }

    bool isJobAssigned = await _assignJob(jobId: response['id']);
    if (!isJobAssigned) return;

    _saveJob(false);
  }

  Future<bool> _assignJob({
    required int jobId,
  }) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    String role = Preference.getStr(Preference.userRole);
    int userId = Preference.getInt(Preference.userId);
    bool isWorkshopContactPerson = (role == 'workshopcontactperson');
    int surveyorEmployeeId = isWorkshopContactPerson ? 0 : userId;
    int workshopEmployeeId = isWorkshopContactPerson ? userId : 0;

    _apiCalling = true;
    _updateUi;
    final response = await Api(scaffoldMessengerState).assignMSJob({
      'job_id': jobId.toString(),
      'jobjssignedto_surveyorEmpId': surveyorEmployeeId.toString(),
      'jobassignedto_workshopEmpid': workshopEmployeeId.toString(),
      'user_role': role,
    });
    _apiCalling = false;
    _updateUi;

    if (response.runtimeType == String &&
        response.startsWith(Api.defaultError)) {
      ASnackBar.showError(scaffoldMessengerState, response);
      return false;
    } else if (response == Api.internetError) {
      return false;
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
      return false;
    }

    return true;
  }

  Future<void> _saveJob(bool offline) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    if (offline) {
      _data['is_offline'] = offline ? 'yes' : 'no';
      _data['created_at'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _saveOffline;
    }

    ASnackBar.showSnackBar(scaffoldMessengerState,
        offline ? 'Job saved locally' : 'Job created successfully', 0,
        status: Api.success);

    navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) => const HomeScreen(),
        ),
        (route) => false);
  }

  get _saveOffline =>
      LocalJobs.addOfflineJob(platformType: platformTypeMS, job: _data);

  get _updateUi => setState(() {});

  String _getData(String key) => (_data[key] ?? '').toString();
}
