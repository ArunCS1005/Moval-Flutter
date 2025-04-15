import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/local_client_list.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/ui/home_screen/home_screen_ui.dart';
import 'package:moval/ui/home_screen/home_view_ui.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/widget/header.dart';
import 'package:moval/widget/search_drop_down.dart';

import '../../api/api.dart';
import '../../widget/a_snackbar.dart';
import '../../widget/a_text.dart';
import '../../widget/button.dart';
import '../../widget/edit_text.dart';

class MVAddNewJob extends StatefulWidget {
  const MVAddNewJob({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddNewJob();
  }
}

class _AddNewJob extends State<MVAddNewJob> {
  final SearchDropDownController _searchDropDownController =
      SearchDropDownController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, dynamic> _data = {};
  final List _clientList = [];
  final List _branchList = [];
  final List _contactPersonList = [];
  int _backTapCount = 0;
  bool _apiCalling = false;

  @override
  void initState() {
    _initiatePage();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  get _body => SingleChildScrollView(
        controller: _scrollController,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                EditText(
                  'Enter Vehicle Registration No',
                  'vehicle_reg_no',
                  _data,
                  isCapital: true,
                ),
                EditText('Enter Vehicle Owner Name', 'owner_name', _data,
                    isTitleCase: true),
                EditText(
                  'Enter Address',
                  'address',
                  _data,
                ),
                EditText(
                  'Enter inspection place',
                  'inspection_place',
                  _data,
                ),
                SearchDropDown(
                  'Enter report requested by',
                  'requested_by_name',
                  _data,
                  _clientList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                ),
                SearchDropDown(
                  'Branch',
                  'branch_name',
                  _data,
                  _branchList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                ),
                SearchDropDown(
                  'Contact Person',
                  'contact_person_name',
                  _data,
                  _contactPersonList,
                  controller: _searchDropDownController,
                  manualEnter: false,
                ),
                EditText(
                  'Enter contact person mobile no.',
                  'contact_mobile_no',
                  _data,
                  number: true,
                  onSubmitted: onAddJob,
                ),
              ],
            ),
          ),
          Button(
            'Add Claim',
            progress: _apiCalling,
            onTap: onAddJob,
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

  onAddJob() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    if (_apiCalling) return;

    FocusScope.of(context).requestFocus(FocusNode());

    if (_getData('vehicle_reg_no').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Vehicle Registration No Required', 0);
      return;
    } else if (_getData('owner_name').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Owner Name Required', 0);
      return;
    } else if (_getData('address').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Address Required', 0);
      return;
    } else if (_getData('inspection_place').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Inspection Place Required', 0);
      return;
    } else if (_getData('requested_by').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Select Report Requested By', 0);
      return;
    } else if (_getData('branch_name').isEmpty) {
      ASnackBar.showSnackBar(scaffoldMessengerState, 'Select Branch', 0);
      return;
    } else if (_getData('contact_person_name').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Select Contact Person', 0);
      return;
    } else if (_getData('contact_mobile_no').isEmpty) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Mobile Number Required', 0);
      return;
    } else if (_getData('contact_mobile_no').length != 10) {
      ASnackBar.showSnackBar(
          scaffoldMessengerState, 'Mobile Number must be 10 digits', 0);
      return;
    }

    _apiCalling = true;
    _updateUi;

    _data['is_offline'] = 'no';

    final response = await Api(scaffoldMessengerState).createMVJob(_data);

    if (response.runtimeType == String &&
        response.startsWith(Api.defaultError)) {
      ASnackBar.showError(scaffoldMessengerState, response);
    } else if (response == Api.internetError) {
      _saveJob(true);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _saveJob(false);
    }

    _apiCalling = false;
    _updateUi;
  }

  _saveJob(bool offline) async {
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
    await Future.delayed(const Duration(seconds: 1));

    navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) => const HomeScreen(),
        ),
        (route) => false);
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    _searchDropDownController.addHandler(_searchDropDownHandler);
    _searchDropDownController.addScrollListener(_searchDropDownScrollListener);
    _getClientList();
  }

  _searchDropDownHandler(String k, dynamic v) async {
    if (k == 'requested_by_name') {
      _searchDropDownController.invalidate('branch_name', Api.loading);
      _searchDropDownController.invalidate('contact_person_name', Api.loading);
      _data['requested_by'] = v['id'];
      _branchList.clear();
      _contactPersonList.clear();
      _getBranchList(v['id']);
      await Future.delayed(const Duration(milliseconds: 750));
      _searchDropDownController.invalidate('contact_person_name', Api.success);
    } else if (k == 'branch_name') {
      _searchDropDownController.invalidate('contact_person_name', Api.loading);
      _data['branch_id'] = v['id'];
      _contactPersonList.clear();
      _getContactPersonList(v['id']);
    } else if (k == 'contact_person_name') {
      _data['contact_person'] = v['id'];
    }
  }

  _searchDropDownScrollListener(double value) {
    /*final position = _scrollController.offset;
    _scrollController.animateTo(
        position - _value,
        duration: const Duration(milliseconds: 75),
        curve: Curves.linear
    );*/
  }

  _getClientList() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getClientList(
      platform: platformTypeMV,
    );

    log(response.toString());

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _getLocalClientList();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      LocalClientList.saveClients(response);
      _clientList.addAll(response);
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidateAll(Api.success);
      _updateUi;
    }
  }

  _getLocalClientList() async {
    final response = await LocalClientList.getClients();
    _clientList.addAll(response);
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidateAll(Api.success);
    _updateUi;
  }

  _getLocalBranchList(clientId) async {
    // final response = await LocalClientList.getClients();
    // _branchList.addAll(response);
    for (int i = 0; i <= _clientList.length - 1; i++) {
      if (_clientList[i]['id'].toString() == clientId.toString()) {
        _branchList.addAll(_clientList[i]['branch_list']);
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidateAll(Api.success);
    _updateUi;
  }

  _getLocalContactPersonList(branchId) async {
    // final response = await LocalClientList.getContactPerson();
    // _contactPersonList.addAll(response);
    for (int i = 0; i <= _branchList.length - 1; i++) {
      if (_branchList[i]['id'].toString() == branchId.toString()) {
        _contactPersonList.addAll(_branchList[i]['branch_contact']);
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    _searchDropDownController.invalidateAll(Api.success);
    _updateUi;
  }

  get _saveOffline =>
      LocalJobs.addOfflineJob(platformType: platformTypeMV, job: _data);

  get _updateUi => setState(() {});

  _getData(String key) => (_data[key] ?? '').toString();

  _getBranchList(clientId) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState).getBranchList(
      clientId: clientId,
    );

    log(response.toString());

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _getLocalBranchList(clientId);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      LocalClientList.saveBranch(response);
      _branchList.addAll(response);
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidateAll(Api.success);
      _updateUi;
    }
  }

  _getContactPersonList(branchId) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    final response = await Api(scaffoldMessengerState)
        .getContactPersonList(branchId: branchId);

    log(response.toString());

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
      _getLocalContactPersonList(branchId);
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      LocalClientList.saveContactPerson(response);
      _contactPersonList.addAll(response);
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidateAll(Api.success);
      _updateUi;
    }
  }
}
