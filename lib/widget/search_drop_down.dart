
import 'package:flutter/material.dart';
import 'package:moval/api/api.dart';

///
/// @author Gopal Chaudhary || 423u5
///
class SearchDropDown extends StatefulWidget {

  final String                    hint;
  final String                    dataKey;
  final Map                       data;
  final List                      options;
  final SearchDropDownController? controller;
  final String                    optionKey;
  final bool                      manualEnter;
  final bool                      isEnabled;

  const SearchDropDown(
      this.hint,
      this.dataKey,
      this.data,
      this.options,
      {
        Key? key,
        this.controller,
        this.optionKey = 'name',
        this.manualEnter = true,
        this.isEnabled = true,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SearchDropDown();
  }
}

class _SearchDropDown extends State<SearchDropDown> {

  final GlobalKey             _key          = GlobalKey();
  final List<String>          _options      = [];
  final TextEditingController _controller   = TextEditingController();
  final double                _dialogHeight = 220;
  String _status                          = Api.loading;

  @override
  void initState() {
    _initiateWidget();
    super.initState();
  }

  _initiateWidget() async {
    widget.data.putIfAbsent(widget.dataKey, () => _data);
    widget.controller?.addListener(widget.dataKey, _listener);

    _controller.text = _data;

    for (var element in widget.options) {
      _options.add(widget.optionKey.isEmpty
          ? element
          : element[widget.optionKey]);
    }

    await Future.delayed(const Duration(milliseconds: 75));
    _updateUi;
  }


  _listener(String status) {
    _status = status;
    if(status == Api.success) {
      _options.clear();
      for (var element in widget.options) {
        _options.add(widget.optionKey.isEmpty
            ? element
            : element[widget.optionKey] ?? '');
      }
    } else if(status == Api.loading) {
      widget.data[widget.dataKey] = '';
      _controller.text = _data;
      _options.clear();
    } else if(status == 'updateValue') {
      _controller.text = _data;
    }
    _updateUi;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        key: _key,
        onTap: widget.isEnabled ? _onTap : null,
        child: TextField(
          enabled: false,
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.black54),
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
            suffixIcon: _status == Api.loading
                ? Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      height: 13,
                      width: 13,
                      child: CircularProgressIndicator(strokeWidth: 1.2),
                    ),
                  )
                : const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ),
    );
  }


  _onTap() async {

    FocusScope.of(context).requestFocus(FocusNode());

    RenderBox box = _key.currentContext?.findRenderObject() as RenderBox;

    final dy             = box.localToGlobal(Offset.zero).dy;

    final maxHeight      = MediaQuery.of(context).size.height;
    final availableSpace = maxHeight - _dialogHeight - 350;

    double top = dy;

    if(availableSpace < dy){
      top = dy - (dy - availableSpace);
      widget.controller?.invalidateScroll(-(dy - availableSpace));
    }

    final response = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) => _DropDown(
          widget.hint, _options,
          selected: _controller.text,
          top: top,
          height: _dialogHeight,
          searchDropDownController: widget.controller,
      ),
    );


    if (response == null || !(widget.manualEnter || _options.contains(response))) return;

    _controller.text = response.toString();
    widget.data[widget.dataKey] = response;
    widget.controller?.invalidateHandler(widget.dataKey, _getOptionItem(response));

  }


  _getOptionItem(response) {
    for(var item in widget.options) {
      if (widget.optionKey.isEmpty && item == response) {
        return item;
      } else if (widget.optionKey.isNotEmpty &&
          item[widget.optionKey] == response) {
        return item;
      }
    }
    return null;
  }


  get _data => widget.data[widget.dataKey] ?? '';


  get _updateUi => setState((){});

}


class _DropDown extends StatefulWidget {

  final String hint;
  final double top;
  final List   items;
  final String selected;
  final double height;
  final SearchDropDownController? searchDropDownController;

  const _DropDown(
      this.hint,
      this.items,
      {Key? key,
        this.top = 0,
        this.selected = '',
        this.height = 220,
        this.searchDropDownController,
      }) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return _DropDownState();
  }
}


class _DropDownState extends State<_DropDown> {

  final List   _filteredItems             = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _filteredItems.addAll(widget.items);
    _controller.text = widget.selected;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10.0,
      insetPadding: EdgeInsets.only(top: widget.top - 5, left: 15, right: 15),
      alignment: Alignment.topLeft,
      child: Container(
        height: widget.height,
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [ BoxShadow(color: Colors.black12) ]),
        width: double.maxFinite,
        child: Stack(
          children: [
            _inputBox,
            _bodyBuilder,
          ],
        ),
      ),
    );
  }

  get _inputBox => Container(
    padding: const EdgeInsets.all(5),
    alignment: Alignment.topCenter,
    child: TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      onSubmitted: (value) => Navigator.pop(context, value),
      decoration: InputDecoration(
        hintText: widget.hint,
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
        suffixIcon: const Icon(Icons.keyboard_arrow_up),
      ),
    ),
  );

  get _bodyBuilder =>
      Padding(
        padding: const EdgeInsets.only(top: 60, bottom: 5),
        child: _body(),
      );

  _body() {
    if (_filteredItems.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
        itemBuilder: (context, index) => _item(index),
        itemCount: _filteredItems.length,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
      );
    } else if(_filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'Matched data not found!!',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
  }

  _item(int index) {
    return InkWell(
      onTap: () => Navigator.pop(context, _filteredItems[index]),
      child: Container(
        padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
        child: Text(
          _filteredItems[index],
          style: TextStyle(
              fontSize: 16,
              color: _isEqual(_filteredItems[index], widget.selected)
                  ? Colors.blue
                  : Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  _onTextChanged(String value) {
    _filteredItems.clear();
    for(String item in widget.items) {
      if (_isContains(item, value)) {
        _filteredItems.add(item);
      }
    }
    _updateUi;
  }

  // ignore: unused_element
  _onTap() {
    Navigator.pop(context, _controller.text);
  }

  get _updateUi => setState((){});

  _isContains(String a1, String a2) => a1.toLowerCase().contains(a2.toLowerCase());

  _isEqual(String a1, String a2) => a1.toLowerCase() == a2.toLowerCase();

}


class SearchDropDownController {
  static const String _handlerKey = '_handler';
  static const String _scrollKey = '_scrollKey';

  final _listener = {};
  final Map<String, void Function(String k, dynamic v)> _handler = {};
  final Map<String, void Function(double value)> _scrollListener = {};

  addListener(String key, Function(String status) listener) =>
      _listener[key] = listener;

  void addScrollListener(void Function(double value) listener) {
    _scrollListener[_scrollKey] = listener;
  }

  void addHandler(void Function(String k, dynamic v) handlerListener) {
    _handler[_handlerKey] = handlerListener;
  }

  void invalidateHandler(String k, dynamic v) {
    if (!_handler.containsKey(_handlerKey)) return;
    _handler[_handlerKey]!(k, v);
  }

  invalidate(String key, String status) => _listener[key]?.call(status);

  void invalidateScroll(double value) {
    if(!_scrollListener.containsKey(_scrollKey)) return;
    _scrollListener[_scrollKey]!(value);
  }

  invalidateAll(String status) =>
      _listener.forEach((key, value) => value.call(status));

  dispose(String key) => _listener.remove(key);

  void disposeHandler() => _handler.remove(_handlerKey);

  listenerKeys() => _listener.keys;
}
