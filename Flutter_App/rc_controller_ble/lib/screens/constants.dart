import 'package:shared_preferences/shared_preferences.dart';

const SERVICE_UUID = "fc96f65e-318a-4001-84bd-77e9d12af44b";
const CHARACTERISTIC_UUID_RX = "94b43599-5ea2-41e7-9d99-6ff9b904ae3a";
const CHARACTERISTIC_UUID_TX = "04d3552e-b9b3-4be6-a8b4-aa43c4507c4d";

const CMD_DC = 0x01;
const CMD_SERVO = 0x02;
const DATA_GAP = 3;

const DEFAULT_MAC_ADDRESS = "d4:d4:da:e3:96:38";
const MAC_ADDRESS_KEY = 'target_mac_address';

Future<String> getTargetMacAddress() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(MAC_ADDRESS_KEY) ?? DEFAULT_MAC_ADDRESS;
}
