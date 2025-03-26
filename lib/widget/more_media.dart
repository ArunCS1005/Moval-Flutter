import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moval/api/api.dart';
import 'package:moval/util/capture_controller.dart';

class MediaGridView extends StatelessWidget {

  final List data;
  final CaptureController? controller;
  final bool isEnable;

  const MediaGridView(
    this.data, {
      Key? key,
        this.controller,
        this.isEnable = false,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    List<Widget> children = [];

    for (int a = 0; a < data.length; a += 4) {
      children.add(getRow(a, a + 4));
    }

    return data.isEmpty
        ? Container()
        : Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
                boxShadow: [BoxShadow(blurRadius: 1, color: Colors.black38)],
                color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          );
  }

  Widget getRow(int a, int z) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Row(
        children: [
          for (int g = a; g < z; g++)
            data.length > g ? _item(data[g]) : _emptyItem,
        ],
      ),
    );
  }

  _item(item) => Expanded(
        flex: 1,
        child: Container(
          height: 65,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InkWell(
                child:
                item['name'].startsWith('http')
                    ? Image.network(item['name'], fit: BoxFit.cover, width: 75, loadingBuilder: _loadingBuilder, errorBuilder: _errorBuilder,)
                    : Image.file(File(item['name']), fit: BoxFit.cover, width: 75, errorBuilder: _errorBuilder,),
                onTap: () => controller?.invalidateOtherMedia('open', item),
              ),
              if (isEnable)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(180))),
                  child: IconButton(
                    iconSize: 12,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.topRight,
                    onPressed: () => controller?.invalidateOtherMedia('remove', item),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              if (isEnable)
                _status(item),
            ],
          ),
        ),
      );



  _status(item) {

    if (item['name'].startsWith('http')) return _success;

    switch (item['status']) {
      case Api.success:
        return _success;
      case Api.defaultError:
      case Api.internetError:
        return Container(width: 75, alignment:  Alignment.center,
          child: InkWell(
            child: const Icon(Icons.file_upload, size: 25, color: Color.fromARGB(100, 255, 0, 0),),
            onTap: ()=> controller?.invalidateOtherMedia('upload', item)),
        );
      case Api.loading:
        return _loader;
      default:
        return Container();
    }
  }


  get _success => Container(
    width: 75,
    margin: const EdgeInsets.only(bottom: 2, right: 2),
    alignment: Alignment.bottomRight,
    child: const Icon(Icons.done_all, size: 15, color: Colors.greenAccent,),
  );



  get _loader => Container(
    width: 75,
    alignment: Alignment.center,
    child: const SizedBox(width: 15, height: 15,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
        backgroundColor: Colors.blue,
      ),
    ),
  );


  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? event) {

    if(event == null) {
      return child;
    }

    return Container(
      width: 75,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1,
        ),
      ),
    );
  }


  Widget _errorBuilder(BuildContext context, Object object, StackTrace? trace) {
    return const SizedBox(
      width: 75,
      child: Center(
        child: Text(
          'Image\nLoad Failed',
          style: TextStyle(fontSize: 8,),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  get _emptyItem => const Expanded(
        flex: 1,
        child: SizedBox(),
      );
}
