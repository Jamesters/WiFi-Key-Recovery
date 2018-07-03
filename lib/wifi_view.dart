import 'package:flutter/material.dart';
import 'wifi_network.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'enum.dart';
import 'wifi_tap.dart';
import 'main.dart';

class NetworkListItem extends StatefulWidget {
  final WiFiNetwork wifi;

  NetworkListItem(this.wifi)
      : super(
          key: new Key(wifi.ssid),
        );

  @override
  NetworkListItemState createState() => NetworkListItemState();

  static NetworkListItemState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<NetworkListItemState>());
}

class NetworkListItemState extends State<NetworkListItem> {
  final WiFiIcon wiFiIcon = new WiFiIcon();
  
  bool _isSelected = false;
  bool get isSelected => _isSelected;
  set isSelected(bool selected){
    setState(() {
      _isSelected = selected;
    });

  }

  @override
  Widget build(BuildContext context) {
    //if (_isSelected == false)
      _isSelected = NetworkListPage.of(context).checkSelected(widget.wifi.ssid);
    return new ListTile(
      title: new Text(widget.wifi.ssid),
      leading: wiFiIcon,
      subtitle: new Text(widget.wifi.wifiKey),
      key: new Key(widget.wifi.ssid),
      selected: _isSelected,
      onTap: () {
        _showQR(context, widget.wifi);
      },
    );
  }

  static String _escapeQR(String data) {
    return data
        .replaceAll("\\", "\\\\")
        .replaceAll("\"", "\\\"")
        .replaceAll("'", "\\'")
        .replaceAll(";", "\\;")
        .replaceAll(":", "\\:");
  }

  // Show the QR code for the network when entry is pressed
  void _showQR(BuildContext context, WiFiNetwork wifi) {
    if (NetworkListPage.of(context).isSelecting()){
      return;
    }
    String encryptionType = "";
    if (wifi.encryption != EncryptionType.None) {
      // This may be a bug, but enum.toString() returns the name of the enum type as well as the option
      encryptionType =
          wifi.encryption.toString().replaceAll("EncryptionType.", '');
    }

    AlertDialog dialog = new AlertDialog(
      title: new Text(wifi.ssid),
      content: new QrImage(
          data: 'WIFI:S:' +
              _escapeQR(wifi.ssid) +
              ';T:' +
              encryptionType +
              ';P:' +
              _escapeQR(wifi.wifiKey) +
              ';H:' +
              wifi.hidden.toString(),
          size: 300.0),
    );
    showDialog(context: context, builder: (context) => dialog);
  }
}
