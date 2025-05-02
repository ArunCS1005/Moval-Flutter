import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:moval/api/api.dart';
import 'package:moval/api/urls.dart';
import 'package:moval/local/local_jobs.dart';
import 'package:moval/ui/home_screen/home_screen_ui.dart';
import 'package:moval/ui/home_screen/widgets/jobs_item.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/ui/util_ui/message.dart';
import 'package:moval/util/preference.dart';

class MVJobs extends StatefulWidget {
  final String jobType;
  final DateController dateController;

  const MVJobs({Key? key, required this.jobType, required this.dateController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _State();
  }

  static State<MVJobs>? of(BuildContext context) =>
      context.findRootAncestorStateOfType<_State>();
}

class _State extends State<MVJobs> with AutomaticKeepAliveClientMixin {

  final ScrollController _scrollController = ScrollController();
  final List             _dataList         = [];

  String _apiResponse  = Api.loading;
  bool   _loadMoreList = false;
  bool   _refreshList  = false;
  int    _currentPage  = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
        child: _body(),
        onRefresh: _refresh
    );
  }


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    widget.dateController.addListener(_dateController, widget.jobType);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }


  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    widget.dateController.dispose(widget.jobType);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  get _funUpdateUi => setState(() {});

  _scrollListener() async {

    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent) {

      if(_loadMoreList || _refreshList) return;
      _loadMoreList = true;
      _funUpdateUi;
      _getData();

    }

  }


  _dateController(String jobType) {
    _currentPage = 0;
    _dataList.clear();
    _apiResponse = Api.loading;
    _funUpdateUi;
    _getData();
  }

  Future _refresh() async {
    if (_loadMoreList || _refreshList) return;
    _refreshList = true;
    _currentPage = 0;
    widget.dateController.clearDate();

    await _getData();
    _refreshList = _loadMoreList = false;

  }


  Future _getLocalData() async {

    _apiResponse = Api.loading;
    _funUpdateUi;

    final response = await LocalJobs.getJobs(
        platformType: platformTypeMV, jobType: widget.jobType);
    final offlineJobs = widget.jobType == pending
        ? await LocalJobs.getJobs(
            platformType: platformTypeMV, jobType: offline)
        : [];

    _dataList.clear();
    _dataList.addAll(offlineJobs);
    _dataList.addAll(response);
    _apiResponse = Api.success;
    _funUpdateUi;
  }


Future _getData() async {
    ScaffoldMessengerState scaffoldMessengerState =
        ScaffoldMessenger.of(context);
    NavigatorState navigatorState = Navigator.of(context);
    final response = await Api(scaffoldMessengerState).searchJobsList(
      platform: platformTypeMV,
      status: widget.jobType,
      page: (_currentPage + 1).toString(),
    );

    if (response == Api.defaultError) {
      _apiResponse = _loadMoreList ? Api.success : response;
    } else if (response == Api.internetError) {
      await _getLocalData();
    } else if (response == Api.authError) {
      UiUtils.authFailed(navigatorState);
    } else {
      _apiResponse = Api.success;

      // Ensure response['data'] is a list or default to an empty list
      List<dynamic> data = response['data'] ?? [];

      if (!_loadMoreList) _dataList.clear();
      _dataList.addAll(data);

      _currentPage = response['pagination']['current_page'];

      LocalJobs.saveJobs(
          platformType: platformTypeMV,
          jobType: widget.jobType,
          data: _dataList);

      final offlineJobs = widget.jobType == pending && !_loadMoreList
          ? await LocalJobs.getJobs(
              platformType: platformTypeMV, jobType: offline)
          : [];
      _dataList.insertAll(0, offlineJobs);
      _funUpdateUi;
    }

    _loadMoreList = _refreshList = false;
    _funUpdateUi;
  }



  _body() {
    switch (_apiResponse) {
      case Api.loading:
        return _loading;
      case Api.success:
        return _dataList.isNotEmpty
            ? _list
            : const Message('Data not found!!!', scrollable: true,);

      case Api.defaultError:
        return const Message('Something went wrong.\nTry again later!!!', scrollable: true,);

      case Api.internetError:
        return Message(
          'Can\'t connect to server. Please check network connectivity.\nTry again later!!!',
          btn: 'Load Local',
          onTap: _getLocalData,
          scrollable: true,);
    }
  }


  get _list => ListView.builder(
        itemBuilder: (context, index) => _dataList.length == index
            ? _loaderMore
            : JobsItem(
                {
                  ..._dataList[index],
                  'platform': platformTypeMV,
                },
                onResponse: _onResponse,
              ),
        controller: _scrollController,
        itemCount: _dataList.length + (_loadMoreList ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
      );

  get _loaderMore => const Align(
        alignment: Alignment.center,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 35),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2,),
            ),
        ),
      );


  get _loading => const Align(
    alignment: Alignment.center,
    child:
    SizedBox(
      width: 25,
      height: 25,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    ),
  );

  _onResponse(response) {
    if (response == 'submitted') {
      widget.dateController.invalidate();
    } else if (response == 'update') {
      widget.dateController.invalidateByKey(widget.jobType);
    } else if(response == 'hard_refresh') {
      // Hard refresh both Pending Claims and To be Approved pages
      widget.dateController.invalidate();
    } else if(Preference.getStr('offline') == 'reload'){
      Preference.setValue('offline', '');
      _refresh();
    }
  }

}