



import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:moval/ui/home_screen/home_screen_ui.dart';
import 'package:moval/util/preference.dart';
import 'package:moval/widget/app_bar_home.dart';

import '../../../widget/a_text.dart';

class ImgPager extends StatelessWidget {

  final List<Widget> tabs;
  final List<Widget> tabView;
  final TabController? tabController;
  final DateController dateController;

  const ImgPager({Key? key, required this.tabs, required this.tabView, required this.tabController, required this.dateController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBarHome(
      child: Column(
        children: [
          /*Row(children: [
            const SizedBox(width: 20,),
            Expanded(child: DateRangeSelector(Preference.fromDate, dateController)),
            const SizedBox(width: 10,),
            Expanded(child: DateRangeSelector(Preference.toDate, dateController)),
            const SizedBox(width: 20,),
          ],),*/
          TabBar(
            padding: EdgeInsets.zero,
            controller: tabController,
            tabs: tabs,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 4,
            indicatorColor: Colors.red,
          ),
          const SizedBox(height: 10,),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: tabView,
            ),
          ),
        ],
      ),
    );
  }
}

class DateRangeSelector extends StatefulWidget {

  final String _date;
  final DateController _dateController;

  const DateRangeSelector(this._date, this._dateController, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DateRangeSelector();
  }

}

class _DateRangeSelector extends State<DateRangeSelector> {


  @override
  void initState() {
    Preference.setValue(widget._date, '');
    widget._dateController.addClearDateListener(widget._date, ()=> _updateUi);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(border: Border.all(color: Colors.black26), color: Colors.white),
      child: InkWell(
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                'assets/images/calender.svg',
              ),
            ),
            AText(
              Preference.getStr(widget._date).isEmpty
                  ? _placeHolder
                  : _datePlaceholder,
              textColor: const Color.fromARGB(179, 0, 0, 0),
              fontSize: 12,
              fontWeight: FontWeight.w200,
              margin: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ],
        ),
        onTap: () {
          selectDate(context);
        },
      ),
    );
  }

  Future<void> selectDate(BuildContext context) async {

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: Preference.getStr(widget._date).isEmpty
          ? DateTime.now()
          : DateTime.parse(Preference.getStr(widget._date)),
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
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.red)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {

      Preference.setValue(widget._date, DateFormat('yyyy-MM-dd').format(pickedDate));
      widget._dateController.invalidate();
      _updateUi;

    }
  }

  get _updateUi => setState((){});

  get _placeHolder => widget._date == Preference.fromDate ? 'From Date' : 'To Date';

  get _datePlaceholder => DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(Preference.getStr(widget._date)));

}
