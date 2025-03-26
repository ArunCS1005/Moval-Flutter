import 'package:flutter/material.dart';
import 'package:moval/util/routes.dart';

class SearchBar extends StatefulWidget {

  final String hint;
  final int  lines;
  final EdgeInsets margin;

  const SearchBar(
      this.hint,
      {
        Key? key,
        this.lines   = 1,
        this.margin  = const EdgeInsets.only(right: 10, left: 10),
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SearchBar();
  }
}

class _SearchBar extends State<SearchBar> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: widget.margin,
      padding: const EdgeInsets.only(right: 5),
      decoration: const BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
          ),
      ], color: Colors.white),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, Routes.search),
        child: TextField(
          style: const TextStyle(fontSize: 14,color: Colors.black,backgroundColor: Colors.white),
          maxLines: widget.lines,
          enabled: false,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isCollapsed: false,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search,color: Colors.red,),
          ),
        ),
      ),
    );
  }

}