import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:send_location/bgService_controller.dart';
import 'package:send_location/location_controller.dart';
import 'package:send_location/permission_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: SplashScreen(), // A temporary splash screen to check permissions
      getPages: [
        GetPage(name: '/home', page: () => const HomeScreen()),
        // Define your main screen
      ],
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Call checkPermissions() when the splash screen loads
    final permissionController = Get.put(PermissionController());
    permissionController.checkPermissions();

    return const Scaffold(
      body: Center(
        child: Text("Checking permissions..."),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final BackgroundServiceController _backgroundServiceController =
        Get.put(BackgroundServiceController());

    final LocationController _locationController =
        Get.put(LocationController());

    return Scaffold(
      body: Center(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _backgroundServiceController.updateText.value,
                    style: const TextStyle(fontSize: 18),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        GoogleAuthApi.signInAndGetAuthDetails();

                        sendCurrentLocation("currentLatLong");
                      },
                      child: const Text("Email"))
                ],
              ))),
    );
  }
}
