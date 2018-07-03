import 'package:flutter/material.dart';
import 'main.dart';
import 'wifi_view.dart';

class WiFiIcon extends StatefulWidget{

  //WiFiIcon();
  @override
  WiFiIconState createState() => WiFiIconState();

  static WiFiIconState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<WiFiIconState>());
}

class WiFiIconState extends State<WiFiIcon>{
  bool _isSelected = false;  


  void _handleStartSelection(BuildContext context){
    NetworkListPage.of(context).addSelection(NetworkListItem.of(context).widget);
    NetworkListItem.of(context).isSelected = true;
    _isSelected = true;
  }

  void _handleEndSelection(BuildContext context){
    NetworkListPage.of(context).removeSelection(NetworkListItem.of(context).widget);
    NetworkListItem.of(context).isSelected = false;
    _isSelected = false;
  }

  void togleIcon(BuildContext context){
    setState(() {
      if(_isSelected){
        _handleEndSelection(context);
      }else {
        _handleStartSelection(context);
      }
    });
  }

  @override
  Widget build(BuildContext context){
    //if (_isSelected == false)
      _isSelected = NetworkListPage.of(context).checkSelected(NetworkListItem.of(context).widget.wifi.ssid);
    return new Container(
      padding: new EdgeInsets.all(0.0),
      child: new IconButton(
        icon: (_isSelected
            ? new Icon(Icons.check, color: Colors.black,)
            : new Icon(Icons.wifi, color: Colors.blue)),
        onPressed: () {
          togleIcon(context);},    
      ),
    );
  }
}