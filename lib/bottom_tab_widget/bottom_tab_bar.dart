import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moval/widget/a_text.dart';

class BottomTabBarItem {
  BottomTabBarItem({required this.iconData, required this.text});
  String iconData;
  String text;
}

class BottomTabBar extends StatefulWidget {
  BottomTabBar({Key? key,
    required this.items,
    this.height =  55.0,
    this.iconSize = 24.0,
    this.backgroundColor = Colors.white,
    this.color = Colors.red,
    this.selectedColor = Colors.red,
    this.notchedShape = const CircularNotchedRectangle(),
    this.selectedIndex = 0,//----------- this is for the curve in bottom tab
    required this.onTabSelected,
  }) : super(key: key) {
    assert(items.length == 2 || items.length == 4);
  }
  final List<BottomTabBarItem> items;
  final double height;
  final double iconSize;
  final Color backgroundColor;
  final Color color;
  final Color selectedColor;
  final NotchedShape notchedShape;
  final ValueChanged<int> onTabSelected;
  late final int selectedIndex;

  @override
  State<StatefulWidget> createState() => BottomTabBarState();
}

class BottomTabBarState extends State<BottomTabBar> {
  // int _selectedIndex = widget.selectedIndex;

  _updateIndex(int index) {
    widget.onTabSelected(index);
    setState(() {
      // widget.selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = List.generate(widget.items.length, (int index) {
      return _buildTabItem(
        item: widget.items[index],
        index: index,
        onPressed: _updateIndex,
      );
    });
    items.insert(items.length >> 1, _buildMiddleTabItem());

    return BottomAppBar(
      shape: widget.notchedShape,
      color: widget.backgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }

  Widget _buildMiddleTabItem() {
    return Expanded(
      child: SizedBox(
        height: widget.height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: widget.iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BottomTabBarItem item,
    required int index,
    required ValueChanged<int> onPressed,
  }) {
    // Color color = _selectedIndex == index ? const Color(0xffffeded) : Colors.white;
    // Color colorText = _selectedIndex == index ? Colors.black : Colors.white;
    bool isVisibleSelection = widget.selectedIndex == index ? true : false;
    return Expanded(
      child: SizedBox(
        height: widget.height,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onPressed(index),
            child: showItems(isVisibleSelection,item)
          ),
        ),
      ),
    );
  }

  showItems(bool isVisibleSelection, BottomTabBarItem item) {
    if(isVisibleSelection){
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 14),
          decoration: BoxDecoration(
          color: const Color(0xffffeded),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: widget.iconSize, height: widget.iconSize, child: SvgPicture.asset('assets/images/${item.iconData}',),),
            const SizedBox(width: 2.0,),
            AText(item.text,textColor: Colors.black,fontSize: 14,fontWeight: FontWeight.w600,)
          ],
        ),
      );
    }else{
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: widget.iconSize, height: widget.iconSize,  child: SvgPicture.asset('assets/images/${item.iconData}',),)
        ],
      );
    }
  }
}