import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<dynamic> fetchAirQuality(double lat, double long) async{
  final response = await http.get(Uri.parse("http://api.airvisual.com/v2/nearest_city?lat=$lat&lon=$long&key=6e30b967-a864-4b54-b11f-e13ec754629f"));
  return jsonDecode(response.body);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<Position> getLocation () async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
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
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold (
        appBar: AppBar (
          title: const Text("Try http request"),
        ),
        body: FutureBuilder (
          future: getLocation(),
          builder: (ctx, AsyncSnapshot<Position> response) {
            if(response.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            print(response.data!.latitude);
            print(response.data!.longitude);

            return FutureBuilder(
                future: fetchAirQuality (response.data!.latitude, response.data!.longitude),
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  print (snapshot.data);
                  ReadAirCondition(snapshot);
                  return const Scaffold();
              }
            );
          },
        ),
      ),
    );
  }

  void ReadAirCondition (AsyncSnapshot<dynamic> snapshot) {
    if (snapshot.data == null) return;
    String city = snapshot.data["data"]["city"];
    String country = snapshot.data["data"]["country"];
    String temperature = snapshot.data["data"]["current"]["weather"]["tp"].toString();
    String aqi = snapshot.data["data"]["current"]["pollution"]["aqius"].toString();
  }
}
