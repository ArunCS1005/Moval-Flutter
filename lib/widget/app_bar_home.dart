import 'package:flutter/material.dart';

import 'search_bar.dart' as searchbar;

class AppBarHome extends StatelessWidget{
  final double height;
  final Widget? child;
  const AppBarHome({Key? key, this.child, this.height = 65,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appbar = Container(
      padding: const EdgeInsets.only(right: 10,left: 10,top: 10,bottom: 5),
      child: const Row(
        children: [
          // Container(
          //   margin: const EdgeInsets.only(left: 5.0),
          //   height: 30,
          //   width: 30,
          //   decoration: const BoxDecoration(
          //     shape: BoxShape.circle,
          //     color: Color.fromARGB(255, 196, 196, 196),
          //   ),
          // ),
          Expanded(child:  searchbar.SearchBar('Search')),
          // InkWell(child: Container(
          //   width: 30,
          //   height: 30,
          //   padding: const EdgeInsets.all(6),
          //   child: SvgPicture.asset('assets/images/calender.svg',),),
          //   onTap: () => selectDate(context,currentDate),)
        ],
      ),
    );

    final child0 = Padding(
      padding: EdgeInsets.only(top: height),
      child: child,
    );
    return Scaffold(
      body: Stack(
          children: [
            appbar,
            child0,
          ],
        ),
    );
  }

  Future<void> selectDate(BuildContext context,DateTime currentDate) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2015),
        lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },);
    if (pickedDate != null && pickedDate != currentDate) {
      currentDate = pickedDate;
    }
  }
}