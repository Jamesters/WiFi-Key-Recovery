
import 'enum.dart';

class WiFiNetwork{

  final String ssid;
  final EncryptionType encryption;
  final String wifiKey;
  final bool hidden;

  WiFiNetwork({
    this.ssid,
    this.encryption,
    this.wifiKey,
    this.hidden,
    });
}
