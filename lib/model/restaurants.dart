//Establish a class to store the json data for the resturant list
class Restaurants{
  int id;
  String name;
  String address1;
  String address2;
  double latitude;
  double longitude;
  double distance;

  Restaurants(
    {required this.id, required this.name, required this.address1, required this.address2, required this.latitude, required this.longitude, required this.distance});
}