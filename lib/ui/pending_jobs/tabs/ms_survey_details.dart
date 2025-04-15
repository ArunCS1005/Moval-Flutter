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
  bool _sameAsWorkshop = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initiatePage();
    });
  }

  _initiatePage() async {
    await Future.delayed(const Duration(milliseconds: 75));
    log('MS Survey Details: Initializing page');
    widget._pagerController.addResponseListener(vehicleDetail, _onResponse);
    widget._pagerController.addButtonListener(1, _next);
    widget._pagerController
        .addIdListener(vehicleDetail, (id) {
          log('MS Survey Details: Received ID: $id');
          _data['id'] = id;
        });
    _searchDropDownController.addHandler(_searchDropDownHandler);
    _searchDropDownController.addScrollListener(_searchDropDownScrollListener);
  }

  Future<void> _getBranchList() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    int userId = Preference.getInt(Preference.userId);
    int userParentId = Preference.getInt(Preference.userParentId);
    log('MS Survey Details: Getting branch list, userId: $userId, parentId: $userParentId');

    final response = await Api(scaffoldMessengerState).getBranchList(
      adminId: (userParentId == -1) ? userId : userParentId,
    );

    log('MS Survey Details: Branch list response: $response');

    if (response == Api.defaultError) {
      log('MS Survey Details: Failed to get branch list - defaultError');
    } else if (response == Api.internetError) {
      log('MS Survey Details: Failed to get branch list - internetError, trying local data');
      await _getLocalBranchList();
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get branch list - authError');
      UiUtils.authFailed(navigatorState);
    } else {
      final data = response['values'] ?? [];
      log('MS Survey Details: Received ${data.length} branches');
      LocalBranchList.saveAllBranch(data);
      _branchList.addAll(data);
    }
    _updateUi;
  }

  Future<void> _getLocalBranchList() async {
    log('MS Survey Details: Getting local branch list');
    final response = await LocalBranchList.getAllBranch();
    log('MS Survey Details: Local branch list size: ${response.length}');
    _branchList.addAll(response);
  }

  Future<void> _getClientList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    log('MS Survey Details: Getting client list for branchId: $branchId');

    final response = await Api(scaffoldMessengerState).getClientList(
      platform: platformTypeMS,
      branchId: branchId,
    );

    log('MS Survey Details: Client list response: $response');

    if (response == Api.defaultError || response == Api.internetError) {
      log('MS Survey Details: Failed to get client list - ${response == Api.defaultError ? 'defaultError' : 'internetError'}');
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get client list - authError');
      UiUtils.authFailed(navigatorState);
    } else {
      log('MS Survey Details: Received ${response.length} clients');
      _clientList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getClientBranchList({required int clientId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    log('MS Survey Details: Getting client branch list for clientId: $clientId');

    final response = await Api(scaffoldMessengerState).getClientBranchList(
      clientId: clientId,
    );

    log('MS Survey Details: Client branch list response structure: ${response.runtimeType}');
    log('MS Survey Details: Client branch list response: $response');

    if (response == Api.defaultError || response == Api.internetError) {
      log('MS Survey Details: Failed to get client branch list - ${response == Api.defaultError ? 'defaultError' : 'internetError'}');
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get client branch list - authError');
      UiUtils.authFailed(navigatorState);
    } else if (response is Map) {
      // Handle response as a Map - extract the list of branches
      try {
        // Extract client branches from the response map
        // Check if there's a 'values' or similar key in the map
        if (response.containsKey('values')) {
          var branches = response['values'];
          if (branches is List) {
            log('MS Survey Details: Received ${branches.length} client branches from values key');
            _clientBranchList.addAll(branches);
          }
        } else {
          // If no specific key is found, try to extract all values that look like branches
          log('MS Survey Details: No values key found, checking all keys');
          response.forEach((key, value) {
            if (value is List) {
              log('MS Survey Details: Found list in key: $key with ${value.length} items');
              _clientBranchList.addAll(value);
            } else if (value is Map && value.containsKey('office_code')) {
              // Single branch object
              log('MS Survey Details: Found single branch in key: $key');
              _clientBranchList.add(value);
            }
          });
        }
        
        if (_clientBranchList.isEmpty) {
          // As a last resort, try to add the response itself if it looks like a branch
          if (response.containsKey('office_code')) {
            log('MS Survey Details: Adding response itself as a branch');
            _clientBranchList.add(response);
          } else {
            log('MS Survey Details: Could not find any client branches in response');
          }
        }
      } catch (e) {
        log('MS Survey Details: Error processing client branch list: $e');
      }
    } else if (response is List) {
      // Original behavior if response is a list
      log('MS Survey Details: Received ${response.length} client branches as List');
      _clientBranchList.addAll(response);
    } else {
      log('MS Survey Details: Response is neither a Map nor a List: ${response.runtimeType}');
    }
    
    log('MS Survey Details: Final client branch list size: ${_clientBranchList.length}');
    _updateUi;
  }

  Future<void> _getSopList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    log('MS Survey Details: Getting SOP list for branchId: $branchId');

    final response = await Api(scaffoldMessengerState).getSopList(
      branchId: branchId,
    );

    log('MS Survey Details: SOP list response: $response');

    if (response == Api.defaultError || response == Api.internetError) {
      log('MS Survey Details: Failed to get SOP list - ${response == Api.defaultError ? 'defaultError' : 'internetError'}');
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get SOP list - authError');
      UiUtils.authFailed(navigatorState);
    } else {
      log('MS Survey Details: Received ${response.length} SOPs');
      _sopList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getWorkshopList({required int branchId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    log('MS Survey Details: Getting workshop list for branchId: $branchId');

    final response = await Api(scaffoldMessengerState).getWorkshopList(
      branchId: branchId,
    );

    log('MS Survey Details: Workshop list response: $response');

    if (response == Api.defaultError || response == Api.internetError) {
      log('MS Survey Details: Failed to get workshop list - ${response == Api.defaultError ? 'defaultError' : 'internetError'}');
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get workshop list - authError');
      UiUtils.authFailed(navigatorState);
    } else {
      log('MS Survey Details: Received ${response.length} workshops');
      _workshopList.addAll(response);
    }
    _updateUi;
  }

  Future<void> _getWorkshopBranchList({required int workshopId}) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    log('MS Survey Details: Getting workshop branch list for workshopId: $workshopId');

    final response = await Api(scaffoldMessengerState).getWorkshopBranchList(
      workshopId: workshopId,
    );

    log('MS Survey Details: Workshop branch list response: $response');

    if (response == Api.defaultError || response == Api.internetError) {
      log('MS Survey Details: Failed to get workshop branch list - ${response == Api.defaultError ? 'defaultError' : 'internetError'}');
    } else if (response == Api.authError) {
      log('MS Survey Details: Failed to get workshop branch list - authError');
      UiUtils.authFailed(navigatorState);
    } else {
      log('MS Survey Details: Received ${response.length} workshop branches');
      _workshopBranchList.addAll(response);
    }
    _updateUi;
  }

  _searchDropDownHandler(String k, dynamic v) async {
    log('MS Survey Details: SearchDropDown handler - key: $k, value: $v');
    
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
    log('MS Survey Details: Selected office code: $v');
    _data['office_name'] = v['office_name'] ?? '';
    _editTextController.invalidate('office_name');

    _data['office_address'] = v['office_address'] ?? '';
    _editTextController.invalidate('office_address');
  }

  Future<void> _onSelectedBranch(dynamic v) async {
    log('MS Survey Details: Selected branch: $v');
    _searchDropDownController.invalidate('workshop_name', Api.loading);
    _searchDropDownController.invalidate('selected_sop', Api.loading);
    _searchDropDownController.invalidate('selected_client', Api.loading);

    int branchId = v['id'];
    log('MS Survey Details: Clearing workshop list');
    _workshopList.clear();
    await _getWorkshopList(branchId: branchId);

    log('MS Survey Details: Clearing client list');
    _clientList.clear();
    await _getClientList(branchId: branchId);

    log('MS Survey Details: Clearing SOP list');
    _sopList.clear();
    await _getSopList(branchId: branchId);

    _searchDropDownController.invalidate('workshop_name', Api.success);
    _searchDropDownController.invalidate('selected_sop', Api.success);
    _searchDropDownController.invalidate('selected_client', Api.success);
  }

  Future<void> _onSelectedClient(dynamic v) async {
    log('MS Survey Details: Selected client: $v');
    _searchDropDownController.invalidate('selected_office_code', Api.loading);

    int clientId = v['id'];
    log('MS Survey Details: Clearing client branch list');
    _clientBranchList.clear();
    await _getClientBranchList(clientId: clientId);

    _searchDropDownController.invalidate('selected_office_code', Api.success);
  }

  Future<void> _onSelectedWorkshop(dynamic v) async {
    log('MS Survey Details: Selected workshop: $v');
    if(_sameAsWorkshop) {
      _data['place_of_survey'] = _data['workshop_name'];
      _editTextController.invalidate('place_of_survey');
      _updateUi;
    }

    _searchDropDownController.invalidate('workshop_branch', Api.loading);

    int workshopId = v['id'];
    log('MS Survey Details: Clearing workshop branch list');
    _workshopBranchList.clear();
    await _getWorkshopBranchList(workshopId: workshopId);

    _searchDropDownController.invalidate('workshop_branch', Api.success);
  }

  _onResponse(response) async {
    log("MS Survey Details: Received response: $response");
    try {
      if (response == Api.defaultError) {
        log("MS Survey Details: Received default error response");
        return;
      }
      
      // Deep copy the response to _data
      if (response is Map) {
        log("MS Survey Details: Processing response map with keys: ${response.keys.toList()}");
        response.forEach((k, v) {
          _data[k] = v;
          log("MS Survey Details: Copied key $k with value type: ${v.runtimeType}");
        });
      } else {
        log("MS Survey Details: Response is not a Map: ${response.runtimeType}");
      }
      
      await _getBranchList();
      
      // Debug logging for important fields
      log("MS Survey Details: Response admin_branch_id: ${response['admin_branch_id']}");
      log("MS Survey Details: Response workshop_id: ${response['workshop_id']}");
      log("MS Survey Details: Response client_id: ${response['client_id']}");
      log("MS Survey Details: Response client_branch_id: ${response['client_branch_id']}");
      log("MS Survey Details: Response sop_id: ${response['sop_id']}");
      log("MS Survey Details: Branch list size: ${_branchList.length}");
      
      final selectedBranch = _branchList.firstWhere(
          (e) => e['id'].toString() == response['admin_branch_id'].toString(),
          orElse: () {
            log("MS Survey Details: Could not find branch with id: ${response['admin_branch_id']}");
            return {'branch_name': ''};
          });
      
      log("MS Survey Details: Selected branch: ${selectedBranch['branch_name']}");

      int branchId = (response['admin_branch_id'] is int)
          ? response['admin_branch_id']
          : int.tryParse(response['admin_branch_id'].toString()) ?? -1;
      
      log("MS Survey Details: Loading workshop list for branch ID: $branchId");
      await _getWorkshopList(branchId: branchId);

      log("MS Survey Details: Loading client list for branch ID: $branchId");
      await _getClientList(branchId: branchId);

      log("MS Survey Details: Loading SOP list for branch ID: $branchId");
      await _getSopList(branchId: branchId);

      int clientId = response['client_id'] is int 
          ? response['client_id'] 
          : int.tryParse(response['client_id'].toString()) ?? -1;
      
      log("MS Survey Details: Loading client branch list for client ID: $clientId");
      _clientBranchList.clear(); // Ensure the list is clear before loading new data
      await _getClientBranchList(clientId: clientId);
      
      // Handle case where client branch list might be empty
      if (_clientBranchList.isEmpty) {
        log("MS Survey Details: Warning - client branch list is empty after loading");
        // Create a default client branch if needed
        _clientBranchList.add({
          'id': response['client_branch_id'],
          'office_code': '',
          'office_name': response['office_name'] ?? '',
          'office_address': response['office_address'] ?? ''
        });
      }
      
      final selectedClientBranch = _clientBranchList.firstWhere(
          (e) => e['id'].toString() == response['client_branch_id'].toString(),
          orElse: () {
            log("MS Survey Details: Could not find client branch with id: ${response['client_branch_id']}");
            return {'office_code': '', 'office_name': '', 'office_address': ''};
          });

      int workshopId = response['workshop_id'] is int 
          ? response['workshop_id'] 
          : int.tryParse(response['workshop_id'].toString()) ?? -1;
      
      log("MS Survey Details: Loading workshop branch list for workshop ID: $workshopId");
      await _getWorkshopBranchList(workshopId: workshopId);

      // Find claim type
      try {
        final claimTypeItem = _claimTypeList.firstWhere(
            (e) => e['id'].toString() == response['claim_type'].toString(),
            orElse: () {
              log("MS Survey Details: Could not find claim type with id: ${response['claim_type']}");
              return {'name': ''};
            });
            
        log("MS Survey Details: Found claim type: ${claimTypeItem['name']}");
        _data['claim_type'] = claimTypeItem['name'];
      } catch (e) {
        log("MS Survey Details: Error finding claim type: $e");
      }
      
      // Find workshop
      try {
        final workshopItem = _workshopList.firstWhere(
            (e) => e['id'].toString() == response['workshop_id'].toString(),
            orElse: () {
              log("MS Survey Details: Could not find workshop with id: ${response['workshop_id']}");
              return {'workshop_name': ''};
            });
            
        log("MS Survey Details: Found workshop: ${workshopItem['workshop_name']}");
        _data['workshop_name'] = workshopItem['workshop_name'];
      } catch (e) {
        log("MS Survey Details: Error finding workshop: $e");
      }
      
      // Find workshop branch
      try {
        final workshopBranchItem = _workshopBranchList.firstWhere(
            (e) => e['id'].toString() == response['workshop_branch_id'].toString(),
            orElse: () {
              log("MS Survey Details: Could not find workshop branch with id: ${response['workshop_branch_id']}");
              return {'workshop_branch_name': ''};
            });
            
        log("MS Survey Details: Found workshop branch: ${workshopBranchItem['workshop_branch_name']}");
        _data['workshop_branch'] = workshopBranchItem['workshop_branch_name'];
      } catch (e) {
        log("MS Survey Details: Error finding workshop branch: $e");
      }

      // Find client
      try {
        final clientItem = _clientList.firstWhere(
            (e) => e['id'].toString() == response['client_id'].toString(),
            orElse: () {
              log("MS Survey Details: Could not find client with id: ${response['client_id']}");
              return {'client_name': ''};
            });
            
        log("MS Survey Details: Found client: ${clientItem['client_name']}");
        _data['selected_client'] = clientItem['client_name'];
      } catch (e) {
        log("MS Survey Details: Error finding client: $e");
      }

      // Find SOP
      try {
        log("MS Survey Details: Finding SOP with id: ${response['sop_id']}");
        log("MS Survey Details: SOP list: $_sopList");
        
        final sopItem = _sopList.firstWhere(
            (e) => e['id'].toString() == response['sop_id'].toString(),
            orElse: () {
              log("MS Survey Details: Could not find SOP with id: ${response['sop_id']}");
              return {'sop_name': ''};
            });
            
        log("MS Survey Details: Found SOP: ${sopItem['sop_name']}");
        _data['selected_sop'] = sopItem['sop_name'];
      } catch (e) {
        log("MS Survey Details: Error finding SOP: $e");
      }
      
      _data.addAll({
        'place_of_survey': response['place_survey'],
        'contact_person_name': response['contact_person'],
        'contact_mobile_no': response['contact_no'],
        'selected_office_code': selectedClientBranch['office_code'],
        'office_name': selectedClientBranch['office_name'],
        'office_address': selectedClientBranch['office_address'],
        'selected_branch': selectedBranch['branch_name'],
        'registration_date': response['date_of_appointment'],
      });
      
      // Check if place_of_survey is same as workshop_name to set _sameAsWorkshop flag
      if (_data.containsKey('place_of_survey') && _data.containsKey('workshop_name')) {
        String placeSurvey = _data['place_of_survey']?.toString() ?? '';
        String workshopName = _data['workshop_name']?.toString() ?? '';
        _sameAsWorkshop = (placeSurvey.isNotEmpty && workshopName.isNotEmpty && placeSurvey == workshopName);
        log("MS Survey Details: Setting _sameAsWorkshop to $_sameAsWorkshop based on comparison");
      }
      
      log("MS Survey Details: Data after processing response: $_data");
      _updateUi;

      _searchDropDownController.invalidateAll(Api.success);
      _searchDropDownController.invalidateAll('updateValue');
      _editTextController.invalidateAll();
      _dateController.invalidateAll();
      
    } catch (e, stackTrace) {
      log("MS Survey Details: Error processing response: $e");
      log("MS Survey Details: Stack trace: $stackTrace");
    }
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
    } else if (_getData('place_of_survey').isEmpty && !_sameAsWorkshop) {
      // Only validate place_of_survey if "Same as Workshop" is not selected
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
      'same_as_workshop': _sameAsWorkshop ? '1' : '0', // Added field for API
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
