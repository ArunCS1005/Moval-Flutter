import 'package:flutter/material.dart';
import 'package:moval/dialog/logout_dialog.dart';
import 'package:moval/ui/home_screen/home_view_ui.dart';
import 'package:moval/ui/profile/profile_item_ui.dart';
import 'package:moval/ui/util_ui/UiUtils.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/widget/header.dart';
import '../../util/routes.dart';
import '../../widget/a_text.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget{

  const Profile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _Profile();
  }

}

class _Profile extends State<Profile> {

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }

  get _body => SingleChildScrollView(
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AText(Preference.getStr(Preference.userName), textColor: Colors.black, fontWeight: FontWeight.w600, padding: const EdgeInsets.only(left:20, top: 20),fontSize: 18,),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 50,),
            margin: const EdgeInsets.only(top: 20,),
            decoration: UiUtils.decoration(),
            child: Column(
              children: [
                ProfileItem('Change Password', onTap: _callChangePassword, img: 'change_password.png',),
                ProfileItem('Privacy Policy', onTap: _launchUrl, img: 'privacy_policy.png',),
                ProfileItem('Logout', onTap: _callLogout, img: 'logout.png',),
              ],
            ),
          ),
        ]
    ),
  );


  @override
  Widget build(BuildContext context) {
    String role = Preference.getStr(Preference.userRole);
    return HomeView(
      selectedTab: 1,
      showAddBtn: (role != 'employee' && role != 'Branch Contact'),
      child: Header('Profile',
        child: _body,
      ),
    );
  }

  updateUi() {
    setState(() {});
  }

  _callLogout() {
        showDialog(context: context,
            builder: (BuildContext context) {
              return const LogoutDialog();
            });
  }


  _callChangePassword() {
    Navigator.pushNamed(context, Routes.changePassword);
  }

  _launchUrl() async {
    const url = 'https://techkrate.com/privacy-policy/';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

}