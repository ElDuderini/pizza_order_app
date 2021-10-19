import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pizza_order_app/detail.dart';
import 'package:pizza_order_app/model/restaurants.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pizza Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Pizza time!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
//This class checks to see if the user has location permissions enabled
  void locationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  List<Restaurants> resturantList = [];
  late Position updatedPos;

  //Obtain the list of restuants and the current position of the user
  getResaurants() async {
    try{

    
    //Clear the list when the list refreshes for new distance info
    if(resturantList.isNotEmpty){
      resturantList.clear();
    }

     updatedPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    var response = await http.get(Uri.https(
        "private-anon-03ab229599-pizzaapp.apiary-mock.com", "/restaurants/"));

    //use bodybytes decode to propperly parse accented characters
    var jsonData = jsonDecode(utf8.decode(response.bodyBytes));

    //Add items to the list of restuants by using the data from each entry in jsonData
    for (var i in jsonData) {
      Restaurants restaurant = Restaurants(
          id: i["id"] as int,
          name: i["name"] as String,
          address1: i["address1"] as String,
          address2: i["address2"] as String,
          latitude: i["latitude"] as double,
          longitude: i["longitude"] as double,
          //Use the geolocator API to calculate the distance between the users current location and the resturants lat/long
          distance: Geolocator.distanceBetween(
              i["latitude"], i["longitude"], updatedPos.latitude, updatedPos.longitude));

      resturantList.add(restaurant);
    }
    }
    catch(e){
      print(e);
    }
    //Sort the list items by distance from the user
    resturantList.sort((a, b) => a.distance.compareTo(b.distance));
    return resturantList;
  }

  //When the user pulls down on the list, then update the list and the current distance between the restaurants
  Future<void> refreshList() async{
    print("List refreshed");
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      updatedPos = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          child: FutureBuilder(
            //Build the list view from the information obtained from the getResaurants method
              future: getResaurants(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.data == null) {
                  return Container(
                    child: const Center(
                      child: Text("Loading..."),
                    ),
                  );
                } else {
                  return RefreshIndicator( 
                    onRefresh: () => refreshList(),
                    child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {

                        //Prepare variables for displaying the distance data
                        double distance = snapshot.data[index].distance;
                        String distanceString;

                        //If the distance in meters is greater than or equal to 1000, then display it as kilometers
                        //Otherwise display it as meters
                        if (distance >= 1000) {
                          distanceString =
                              (distance / 1000).toStringAsFixed(2) + "km";
                        } else {
                          distanceString = distance.toStringAsFixed(2) + "m";
                        }

                        //Display the name of the resturant and distance from the user at the time of loading the data
                        return ListTile(
                          title: Text(snapshot.data[index].name,
                              style: GoogleFonts.notoSans()),
                          subtitle: Text(distanceString,
                              style: GoogleFonts.notoSans()),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DetailPage(snapshot.data[index])));
                          },
                        );
                      })
                      );
                }
              }),
        ));
  }
}
