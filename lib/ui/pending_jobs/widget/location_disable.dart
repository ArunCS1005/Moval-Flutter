import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

class LocationDisable extends StatelessWidget {

  const LocationDisable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.redAccent,
              height: 130,
              alignment: Alignment.center,
              child: Image.asset('assets/images/location.png', height: 45, width: 45, color: Colors.white,),
            ),
            Container(
              margin: const EdgeInsets.only(top: 60, bottom: 35),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: const Text(
                'GPS disabled.\nTurn on gps.',
                style: TextStyle(color: Colors.black, fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            InkWell(
              onTap: ()=> AppSettings.openAppSettings(type: AppSettingsType.location),
              child: Container(
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(45),),
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 5),
                  child: const Text('Open setting', style: TextStyle(color: Colors.white, fontSize: 16),)),
            ),
            const SizedBox(height: 12,),
          ],
        ),
      ),
    );
  }

}