import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moval/api/api.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/ui/home_screen/widgets/img_pager.dart';
import 'package:moval/ui/home_screen/widgets/jobs_item.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/ui/util_ui/message.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/widget/a_text.dart';

import '../../widget/search_drop_down.dart';
import 'home_screen_ui.dart';

class SearchUi extends StatefulWidget {
  const SearchUi({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchUiState();
  }
}

class _SearchUiState extends State<SearchUi> {
  final _dataList = [];
  String _apiStatus = Api.loading;
  String _currentJob = '';
  String _searchFor = '';
  final Map<String, dynamic> _temp = {};
  final List _clientList = [];
  final List _employeeList = [];
  final DateController _dateController = DateController();
  final SearchDropDownController _searchDropDownController =
      SearchDropDownController();
  String _clientId = '';
  String _employeeId = '';
  bool _offlineJobs = false;
  bool _isMVJobs = true; // Track whether we're on MV or MS platform
  
  // For debounce
  DateTime? _lastSearchTime;
  final _searchDebounceMs = 500; // 500ms debounce time

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get platform from shared preferences
      String credentialStr = Preference.getStr(Preference.credential);
      if (credentialStr.isNotEmpty) {
        _isMVJobs = (jsonDecode(credentialStr)['platform'] == 0);
      }
      
      switch (Preference.getInt(Preference.currentJob)) {
        case 0:
          _currentJob = pending;
          break;
        case 1:
          _currentJob = submitted;
          break;
        case 2:
          _currentJob = approved;
          _callClientApi();
          _callEmployeeApi();
          break;
        default:
          _currentJob = pending;
      }
      Preference.setValue(Preference.fromDate, '');
      Preference.setValue(Preference.toDate, '');
      _dateController.addListener(_dateHandler, 'search');
      _searchDropDownController.addHandler(_searchDropDownHandler);
      _funOnChanged('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            _AppBar(
              onChanged: _funOnChanged,
              searching: Api.loading == _apiStatus,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 75),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: DateRangeSelector(
                          Preference.fromDate, _dateController)),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: DateRangeSelector(
                          Preference.toDate, _dateController)),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
            if (_currentJob == approved)
              Padding(
                padding: const EdgeInsets.only(top: 115),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: SearchDropDown(
                      'Client',
                      'client',
                      _temp,
                      _clientList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                    )),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: SearchDropDown(
                      'Employee',
                      'employee',
                      _temp,
                      _employeeList,
                      controller: _searchDropDownController,
                      manualEnter: false,
                    )),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
            Padding(
              padding:
                  EdgeInsets.only(top: _currentJob == approved ? 200 : 130),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AText(
                        _dataList.isEmpty
                            ? ''
                            : 'Records found ${_dataList.length}',
                        textColor: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                        padding: const EdgeInsets.only(left: 10, right: 10),
                      ),
                      Row(
                        children: [
                          const AText('Only Offline jobs'),
                          Switch(
                              value: _offlineJobs,
                              onChanged: _offlineJobSwitchChange)
                        ],
                      )
                    ],
                  ),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _searchDropDownHandler(String k, dynamic v) async {
    switch (k) {
      case 'client':
        _clientId = (v['id']).toString();
        _reload();
        break;
      case 'employee':
        _employeeId = (v['id']).toString();
        _reload();
        break;
    }
  }

  _dateHandler(String jobType) async {
    if (jobType != 'search') return;

    _reload();
  }

  _reload() {
    String value = _searchFor;
    _searchFor = '';
    _funOnChanged(value);
  }

  _funOnChanged(String value) async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);

    // Debug log to track search parameters
    print("SEARCH PARAMS - Text: '$value', ClientID: '$_clientId', EmployeeID: '$_employeeId', OfflineOnly: $_offlineJobs");
    print("SEARCH DATES - From: '${Preference.getStr(Preference.fromDate)}', To: '${Preference.getStr(Preference.toDate)}'");

    // Ensure the search term is different before proceeding
    if (value.isNotEmpty && value == _searchFor) return;

    // Debounce logic
    DateTime now = DateTime.now();
    if (_lastSearchTime != null &&
        now.difference(_lastSearchTime!) < Duration(milliseconds: _searchDebounceMs)) {
      return;
    }
    _lastSearchTime = now;

    _searchFor = value; // Update the search term
    _apiStatus = Api.loading; // Set the loading status
    _dataList.clear(); // Clear previous results
    setState(() {}); // Update UI

    // Force search term to be at least 2 characters for better filtering
    String searchTerm = _searchFor.trim();
    if (searchTerm.length == 1) {
      searchTerm = ""; // Clear very short search terms
    }

    final response = await Api(scaffoldMessengerState).searchJobsList(
      platform: _isMVJobs ? platformTypeMV : platformTypeMS,
      status: _currentJob,
      searchBy: searchTerm,
      fromDate: Preference.getStr(Preference.fromDate),
      toDate: Preference.getStr(Preference.toDate),
      employeeId: _employeeId,
      clientId: _clientId,
      onlyOfflineJobs: _offlineJobs,
    );

    // Debug log for response
    if (response != Api.defaultError && 
        response != Api.internetError && 
        response != Api.authError && 
        response != Api.noData) {
      print("SEARCH RESULTS - Found: ${response["values"]?.length ?? 0} items");
    }

    if (response == Api.defaultError) {
      _apiStatus = response;
    } else if (response == Api.internetError) {
      _apiStatus = response;
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else if (response == Api.noData) {
      _apiStatus = Api.success; // Set success status
      _dataList.clear(); // Ensure list is empty
    } else {
      _apiStatus = Api.success; // Set success status
      _dataList.clear(); // Clear the list before adding new results
      _dataList.addAll(response["values"]); // Update with new results
    }

    setState(() {}); // Refresh the UI
  }

  _body() {
    /// Error
    if (_apiStatus == Api.defaultError) {
      return const Message('Something went wrong.\nTry again later!!!');
    }

    ///internet error
    else if (_apiStatus == Api.internetError) {
      return const Message(
          'Can\'t connect to server. Please check network connectivity.\nTry again later!!!');
    }

    /// No Data Found
    else if (_apiStatus == Api.success && _dataList.isEmpty) {
      return const Message(
        'Data not found!!!',
        scrollable: true,
      );
    } else {
      return ListView.builder(
        itemBuilder: (context, index) => JobsItem(
          {
            ..._dataList[index],
            'job_status': _currentJob,
            'platform': _isMVJobs ? platformTypeMV : platformTypeMS,
          },
          onResponse: _onResponse,
        ),
        itemCount: _dataList.length,
        physics: const BouncingScrollPhysics(),
      );
    }
  }

  _onResponse(response) {
    if (response == null) return;
    _reload();
  }

  _offlineJobSwitchChange(bool value) {
    _offlineJobs = value;
    _reload();
  }

  _callClientApi() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    final response = await Api(scaffoldMessengerState).getClientList(
      platform: _isMVJobs ? platformTypeMV : platformTypeMS,
    );

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _clientList.addAll(response);
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidate('client', Api.success);
    }
  }

  _callEmployeeApi() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    final response = await Api(scaffoldMessengerState).getEmployeeList();

    if (response == Api.defaultError) {
    } else if (response == Api.internetError) {
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _employeeList.addAll(response);
      await Future.delayed(const Duration(seconds: 1));
      _searchDropDownController.invalidate('employee', Api.success);
    }
  }
}

class _AppBar extends StatelessWidget {
  final Function(String)? onChanged;
  final bool searching;

  const _AppBar({Key? key, this.onChanged, this.searching = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 45,
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: SvgPicture.asset('assets/images/back-arrow.svg'),
            ),
          ),
          Expanded(
            child: Container(
              height: 35,
              margin: const EdgeInsets.only(left: 10, right: 10),
              padding: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  spreadRadius: 2,
                )
              ]),
              child: TextField(
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search",
                    isDense: true,
                    prefixIcon: _prefixIcon),
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                autofocus: true, // Auto-focus the search field
              ),
            ),
          ),
        ],
      ),
    );
  }

  get _prefixIcon => searching
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        )
      : const SizedBox(
          height: 45,
          width: 45,
          child: Icon(
            Icons.search,
            color: Colors.red,
          ),
        );
}
