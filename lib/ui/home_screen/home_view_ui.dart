import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../bottom_tab_widget/bottom_tab_bar.dart';
import '../../util/preference.dart';
import '../../util/routes.dart';

class HomeView extends StatefulWidget {

  final Widget? child;
  final int selectedTab;
  final int addJob;
  final bool showAddBtn;

  const HomeView({Key? key, this.child, this.selectedTab = 0, this.addJob = 0, this.showAddBtn = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeView();

}

class _HomeView extends State<HomeView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widget.child,
      bottomNavigationBar: BottomTabBar(
        selectedIndex: widget.selectedTab,
        onTabSelected: _onTapped,
        items: [
          BottomTabBarItem(iconData: 'home.svg', text: ''),
          BottomTabBarItem(iconData: 'user.svg', text: ''),
        ],
      ),
      floatingActionButtonLocation: isShowAddButtonLocation(),
      floatingActionButton: isShowAddButton(),
    );
  }


  void _onTapped(int value) {
    if(value == 0){
      if(widget.selectedTab != 0){
        Navigator.of(context)
            .popUntil(ModalRoute.withName(Routes.homeScreen));
      }
    }else if(value == 1){
      if(widget.selectedTab != 1){
        Navigator.pushNamed(context, Routes.profile);
      }
    }
    log('---on tap$value');
  }

  isShowAddButtonLocation() {
    if(widget.showAddBtn){
      return FloatingActionButtonLocation.centerDocked;
    }else {
      return null;
    }
  }

  isShowAddButton() {
    if(widget.showAddBtn){
      return FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (widget.addJob == 0) {
            String credentialStr = Preference.getStr(Preference.credential);
            if (credentialStr.isEmpty) return;
            Navigator.pushNamed(
              context,
              (jsonDecode(credentialStr)['platform'] == 0)
                  ? Routes.mvAddNewJob
                  : Routes.msAddNewJob,
            );
          }
        },
        elevation: 2.0,
        child: const Icon(
          Icons.add,
          color: Colors.red,
          size: 40,
        ),
      );
    }else {
      return null;
    }
  }
}