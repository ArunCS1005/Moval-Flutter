import 'package:flutter/material.dart';
import 'package:moval/ui/pending_jobs/pending_jobs.dart';
import 'package:moval/widget/button.dart';
import 'package:moval/widget/header.dart';

class Pager extends StatelessWidget {

  final String title;
  final List<Widget> tabs;
  final List<Widget> tabView;
  final TabController? tabController;
  final PagerController pagerController;
  final bool showButton;

  const Pager(
    this.title, {
    Key? key,
    required this.tabs,
    required this.tabView,
    required this.tabController,
    required this.pagerController,
    this.showButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Header(
      title,
      doublePressEnable: true,
      child: Stack(
        children: [
          TabBar(
            padding: EdgeInsets.zero,
            controller: tabController,
            tabs: tabs,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            indicatorColor: Colors.red,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: TabBarView(
              controller: tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: tabView,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Button(
              (pagerController.pageIndex < tabs.length - 1) ? 'Next' : 'Submit',
              onTap: pagerController.onButtonClick,
              progress: pagerController.buttonLoading,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              enable:
                  (showButton || (pagerController.pageIndex < tabs.length - 1)),
            ),
          ),
        ],
      ),
    );
  }
}




