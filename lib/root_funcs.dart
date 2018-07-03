import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'wifi_network.dart';
import 'enum.dart';

  bool checkRoot(){
    var results = Process.runSync('su', ['-c','ls /system']);
    if (results.stderr.toString().trim() != "")
      return false;
    return true;
  }
  List<WiFiNetwork> readWiFIConfigurationOreo(){
    List<WiFiNetwork> returnList = [];
    var results = Process.runSync('su', ['-c','cat /data/misc/wifi/WifiConfigStore.xml']);
    if (results.stderr.toString().trim() != "")
      return [];
      // Get the XML from the file
      String resXML = results.stdout;
      // Turn it into an XML Document
      xml.XmlDocument document = xml.parse(resXML);
      // Get the WifiConfiguration Nodes
      var networks = document.findAllElements("WifiConfiguration");
      // Process each one for the SSID
      networks.forEach((n) => returnList.add(getNetworkOreo(n)));
      return returnList;
  }
  WiFiNetwork getNetworkOreo(xml.XmlElement element){
      String networkSSID = "";
      String networkWiFiKey = "";
      String networkEncryption = "";
      EncryptionType encryptionType;
      bool networkHidden = false;

      networkSSID = element.children.where((node) => node is xml.XmlElement && (node.attributes.where((a) => a.value == "SSID").length == 1)).map((n) => n.text).first;
      networkEncryption = element.children.where((node) => node is xml.XmlElement && (node.attributes.where((a) => a.value == "ConfigKey").length == 1)).map((n) => n.text).first;
      networkEncryption = networkEncryption.replaceAll(networkSSID, "");
      if (networkEncryption == "WEP"){
        // Get the WEP Index (0-4)        
        xml.XmlNode nodeWEPKeyIndex = element.children.where((node) => node is xml.XmlElement && (node.attributes.where((a) => a.value == "WEPTxKeyIndex").length == 1)).first;
        int indexWEPKey = int.tryParse(nodeWEPKeyIndex.attributes.where((a) => a.name.local == "value").first.value.toString());
        
        // Get the WEP Keys node (contains 4 children)
        xml.XmlNode nodeWEPKeys =  element.children.where((node) => (node.attributes.where((a) => a.value == "WEPKeys").length == 1)).first;
       
        // Get to the WEP Key by the index
        xml.XmlNode selectedWEPKey = nodeWEPKeys.children.where((n) => n is xml.XmlElement).toList()[indexWEPKey];
        // Pull the Key out of the Value attribute
        networkWiFiKey = selectedWEPKey.attributes.where((a) => a.name.local == "value").first.value;
      } else if (networkEncryption == "WPA_PSK") {
        // This is WPA
        networkWiFiKey = element.children.where((node) => node is xml.XmlElement && (node.attributes.where((a) => a.value == "PreSharedKey").length == 1)).map((n) => n.text).first;
      } else {
        // There is no encryption
        networkWiFiKey = "";
      }
      // Get Hidden SSID true/false
      networkHidden = element.children.where((node) => node is xml.XmlElement && (node.attributes.where((a) => a.value == "SSID").length == 1)).map((n) => n.text)
                .first
                .toString()
                .toLowerCase()
                .replaceAll('"', '') == 'true';
      // <boolean name="HiddenSSID" value="false"/>

      // They are stored in the XML with " at the beginning and end
      if (networkSSID.startsWith('"')) {networkSSID = networkSSID.substring(1);}
      if (networkSSID.endsWith('"')) {networkSSID = networkSSID.substring(0,networkSSID.length - 1);}
      if (networkWiFiKey.startsWith('"')) {networkWiFiKey = networkWiFiKey.substring(1);}
      if (networkWiFiKey.endsWith('"')) {networkWiFiKey = networkWiFiKey.substring(0,networkWiFiKey.length - 1);}
      switch (networkEncryption){
        case "NONE":
          encryptionType = EncryptionType.None;
          break;
        case "WPA_PSK":
          encryptionType = EncryptionType.WPA;
          break;
        case "WEP":
          encryptionType = EncryptionType.WEP;
          break;
        default:
          encryptionType = EncryptionType.None;
      }
      return new WiFiNetwork(
        ssid: networkSSID,
        encryption: encryptionType,
        wifiKey: networkWiFiKey,
        hidden: networkHidden);
        //print("SSID = $SSID\t Encryption = $Encryption\t Key = $Key");
  }
String getSSID(){
    var results = Process.runSync('su', ['-c',"dumpsys netstats | grep -E 'iface=wlan.*networkId'"]);
    if (results.stderr.toString().trim() != "")
      return "";
    return results.stdout.toString().split("networkId")[1].split('"')[1].toString().trim().replaceAll('"',"");

  
}
