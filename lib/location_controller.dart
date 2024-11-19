import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:send_location/permission_services.dart';

class LocationController extends GetxController {
  var currentLocation = "".obs;

  // Update the current location
  Future<void> updateLocation() async {
    Position position = await _getCurrentLocation();
    currentLocation.value =
        "Lat: ${position.latitude}, Lon: ${position.longitude}";

    saveLatLongForToday(position.latitude, position.longitude);
    print("Location Updated: ${currentLocation.value}");
  }

  // Function to get the current location
  Future<Position> _getCurrentLocation() async {
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

//old
// Method to send location via email using Google authentication and mailer
/*
  Future<void> sendLocationViaEmail(String currentLatLong) async {
    final user = await GoogleAuthApi.signIn();

    if (user == null) return;

    final auth = await user.authentication;
    final email = user.email;
    final token = auth.accessToken;

    GoogleAuthApi.signOut();

    final smtpServer = gmailSaslXoauth2(email, token!);

    final message = Message()
      ..from = Address(email, 'Send Location')
      ..recipients.add('vishal.rockymountaintech@gmail.com')
      ..subject = 'Current Location'
      ..text = 'My current location is:\n$currentLatLong';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (error) {
      print('Error sending email: $error');
    }
  }
*/
}

class GoogleAuthApi {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<Map<String, String>?> signInAndGetAuthDetails() async {
    final user = await _googleSignIn.signIn();

    if (user == null) return null;

    final auth = await user.authentication;
    final email = user.email;
    final token = auth.accessToken;


    print(auth);
    print(email);
   // signOut(); // Optionally sign out after obtaining the token

    if (token != null) {
      return {
        'email': email,
        'token': token,
      };
    } else {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

Future<void> sendLocationViaEmail(
    String email, String token, String currentLatLong) async {
  final smtpServer = gmailSaslXoauth2(email, token);

  final message = Message()
    ..from = Address(email, 'Send Location')
    ..recipients.add('vishal.rockymountaintech@gmail.com')
    ..subject = 'Current Location'
    ..text = 'My current location is:\n$currentLatLong';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: ${sendReport.toString()}');
  } catch (error) {
    print('Error sending email: $error');
  }
}

Future<void> sendCurrentLocation(String currentLatLong) async {
  final authDetails = await GoogleAuthApi.signInAndGetAuthDetails();

  print("authDetails $authDetails");
  if (authDetails != null) {
    final email = authDetails['email']!;
    final token = authDetails['token']!;
    await sendLocationViaEmail(email, token, currentLatLong);
  } else {
    print("Google sign-in failed or was cancelled.");
  }
}
