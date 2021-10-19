//Set up class for the json data for restaurant menus

class Menu{
  int id;
  String category;
  String name;
  List<dynamic>? toppings;
  int price;
  int? rank;

  Menu(
    {required this.id, required this.category, required this.name, this.toppings, required this.price, this.rank}
  );
}