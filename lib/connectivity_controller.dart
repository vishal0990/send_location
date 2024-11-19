import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  var isConnected = false.obs;

  // Method to check connectivity status
  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.toString() == ConnectivityResult.mobile.toString() ||
        connectivityResult.toString() == ConnectivityResult.wifi.toString()) {
      isConnected.value = true;
    } else {
      isConnected.value = false;
      _promptToEnableInternet();
    }
  }

  // Method to prompt the user to enable internet
  Future<void> _promptToEnableInternet() async {
    AppSettings.openAppSettingsPanel(AppSettingsPanelType.internetConnectivity);
  }
}
