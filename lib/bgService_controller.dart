import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:send_location/location_controller.dart';

final BackgroundServiceController _backgroundServiceController =
Get.put(BackgroundServiceController());

final LocationController _locationController = Get.put(LocationController());

var currentLocation = "".obs;

Future<void> updateLocation() async {
  Position position = await getCurrentLocation();
  currentLocation.value =
  "Lat: ${position.latitude}, Lon: ${position.longitude}";
  _backgroundServiceController.updateText.value = currentLocation.value;
  //saveLatLongForToday(position.latitude, position.longitude);
  // sendCurrentLocation(currentLocation.value);
  //sendCurrentLocation(currentLocation.value);

  print("Location Updated: ${currentLocation.value}");
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // Check location permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When permissions are granted, get the location
  return await Geolocator.getCurrentPosition();
}

class BackgroundServiceController extends GetxController {
  // State for holding the update text
  var updateText = "No update".obs;

  @override
  void onInit() {
    initializeService();
    _registerListener();
    super.onInit();
  }

  // Initialize the background service
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    getCurrentLocation();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'background_service',
        initialNotificationTitle: 'Background Service',
        initialNotificationContent: 'Service is running in the background',
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        autoStart: true,
      ),
    );

    service.startService();
  }

  // Listen for updates from the background service
  void _registerListener() {
    FlutterBackgroundService().on('update').listen((event) {
      updateText.value = "Updated at ${DateTime.now()}";
      // Here, you can update UI or perform any main-thread actions
      print("Main thread received update at ${updateText.value}");
    });
  }
}

// This is the top-level function for the background service
void onStart(ServiceInstance service) {
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    print("Updating location...");

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Location",
          content: currentLocation
              .value /*"Updated at ${DateFormat('yyyy-MMM-dd HH:mm:ss').format(DateTime.now())}"*/,
        );
      }
    }

    // Trigger the location update in the background
    updateLocation();

    // Send data to the main isolate
    service.invoke('update');
  });

  // Listen to 'update' event and perform actions
  service.on('update').listen((event) {
    print("Received update event");
    // Update the location on the main thread
    updateLocation();
  });
}
