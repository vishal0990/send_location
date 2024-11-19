import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController extends GetxController {
  // Method to check and request all necessary permissions
  Future<void> checkPermissions() async {
    // Define the permissions you need
    final permissions = [
      Permission.location,
      Permission.camera,
      // Permission.microphone,
      Permission.storage, // For Android storage access
      //Permission.photos, // For iOS gallery access
    ];

    for (var permission in permissions) {
      // Check if permission is granted
      if (await permission.isDenied || await permission.isPermanentlyDenied) {
        final status = await permission.request();

        // Handle permission denied and permanently denied cases
        if (status.isDenied) {
          Get.defaultDialog(
            title: "Permission Denied",
            middleText: "${permission.toString()} is required to proceed.",
            textConfirm: "Open Settings",
            textCancel: "Cancel",
            onConfirm: () async {
              await openAppSettings();
              Get.back(); // Close dialog after opening settings
            },
          );
          /*  Get.snackbar(
            "Permission Denied",
            "${permission.toString()} is required to proceed.",
            snackPosition: SnackPosition.BOTTOM,
          );*/
          return;
        } else if (status.isPermanentlyDenied) {
          Get.defaultDialog(
            title: "Permission Required",
            middleText: "${permission.toString()} is required to proceed.",
            textConfirm: "Open Settings",
            textCancel: "Cancel",
            onConfirm: () async {
              await openAppSettings();
              Get.back(); // Close dialog after opening settings
            },
          );
          return;
        }
      }
    }

    createFolder("My Folder");
    // All permissions granted, navigate to main app screen
    Get.offAllNamed('/home'); // Navigate to home page or main screen
  }
}

Future<void> createFolder(String folderName) async {
  try {
    Directory? directory;

    // Check if external storage is available
    if (Platform.isAndroid) {
      if (await _hasExternalStorageAccess()) {
        // For Android 10 and above, use getExternalStorageDirectory
        directory = await getExternalStorageDirectory();
      } else {
        // Fallback to internal app storage if external storage is not available
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // For iOS or other platforms, use internal storage
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      // Define the folder path within the chosen directory
      final Directory folder = Directory('${directory.path}/$folderName');

      // Create the folder if it doesn't exist
      if (!(await folder.exists())) {
        await folder.create(recursive: true);
        print('Folder created at: ${folder.path}');
      } else {
        print('Folder already exists at: ${folder.path}');
      }
    } else {
      print("Could not retrieve app directory.");
    }
  } catch (e) {
    print("Error creating folder: $e");
  }
}

// Helper method to check if external storage can be accessed
Future<bool> _hasExternalStorageAccess() async {
  if (Platform.isAndroid) {
    return (await getExternalStorageDirectory()) != null;
  }
  return false;
}

// Save lat long

Future<void> saveLatLongForToday(double latitude, double longitude) async {
  try {
    // Ensure permissions are requested in the main thread
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Request permissions on the main thread after the widget is built
        if (await Permission.manageExternalStorage.request().isGranted) {
          // If permission is granted, proceed with saving the file
          await _saveLocationToFile(latitude, longitude);
          print("Save file as json");
        } else {
          print("Storage permission is required.");
        }
      });
    } else {
      // Handle iOS or other platforms (you can save directly)
      await _saveLocationToFile(latitude, longitude);
    }
  } catch (e) {
    print("Error saving coordinates: $e");
  }
}

Future<void> _saveLocationToFile(double latitude, double longitude) async {
  final directory = await getApplicationDocumentsDirectory();
  final folderPath = '${directory.path}/My Folder';

  // Create the folder if it doesn't exist
  final folder = Directory(folderPath);
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  // Get today's date in a YYYY-MM-DD format
  final today = DateTime.now();
  final dateStr = "${today.year}-${today.month}-${today.day}";

  // Define the file path using the date (e.g., "2024-11-12.json")
  final filePath = '$folderPath/$dateStr.json';
  final file = File(filePath);

  // Prepare data to save in JSON format
  final latLongData = {
    "date": dateStr,
    "latitude": latitude,
    "longitude": longitude,
  };

  // Check if the file already exists
  if (await file.exists()) {
    // Append new coordinates data to the existing file
    final contents = await file.readAsString();
    final existingData = jsonDecode(contents);
    existingData['locations'].add(latLongData);
    await file.writeAsString(jsonEncode(existingData), mode: FileMode.write);
  } else {
    // Create new JSON structure with the first location of the day
    final newData = {
      "date": dateStr,
      "locations": [latLongData],
    };
    await file.writeAsString(jsonEncode(newData));
  }

  print("Coordinates saved to: $filePath");
}
