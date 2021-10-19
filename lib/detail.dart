import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:badges/badges.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizza_order_app/model/restaurants.dart';

import 'shopping_cart.dart';
import 'package:pizza_order_app/model/cart.dart';
import 'package:pizza_order_app/model/menu.dart';

class DetailPage extends StatelessWidget {
  Restaurants restaurant;

  DetailPage(this.restaurant);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resaurant Menu"),
      ),
      body: Center(
        child: MyDetailPage(restaurant),
      ),
    );
  }
}

class MyDetailPage extends StatefulWidget {
  Restaurants restaurant;

  MyDetailPage(this.restaurant);

  @override
  State<MyDetailPage> createState() => _MyDetailPageState(restaurant);
}

class _MyDetailPageState extends State<MyDetailPage> {
  Restaurants restaurant;

  _MyDetailPageState(this.restaurant);

  List<Menu> menuItems = [];

  int itemsOrdered = 0;

  List<Cart> populatedCart = [];

  //Method used when adding new items to the shopping cart, will update the floating button badge counter
  addToList(int itemId) {
    //Try to find an entry in the list that already has the same itemID
    final cartItem = populatedCart.where((element) => element.itemId == itemId);

    //If there are no entrys like this, then add a new item to the list with a quanity of one
    if (cartItem.isEmpty) {
      populatedCart.add(Cart(itemId: itemId, quantity: 1));
    }
    //If there is an entry like this, then add to the existing quantity
    else {
      int index =
          populatedCart.indexWhere((element) => element.itemId == itemId);
      Cart changedCartItem =
          Cart(itemId: itemId, quantity: cartItem.first.quantity + 1);
      populatedCart[index] = changedCartItem;
    }

    //Use set state to update the badge button on the floating button
    setState(() {
      itemsOrdered++;
    });
  }

  removeFromList(int itemId) {
    final cartItem = populatedCart.where((element) => element.itemId == itemId);

    //If there are no entrys like this, then exit the method to prevent further changes
    if (cartItem.isEmpty) {
      //print("itemNotRemoved");
      return;
    }
    //If there is an entry like this, then remove from the existing quantity
    else {
      int index =
          populatedCart.indexWhere((element) => element.itemId == itemId);

      //If the quantity is only 1, then remove the item from the list compleatly
      if (cartItem.first.quantity == 1) {
        populatedCart.removeAt(index);
      }
      //If it is not, then continue to remove from the existing quantity
      else {
        Cart changedCartItem =
            Cart(itemId: itemId, quantity: cartItem.first.quantity - 1);
        populatedCart[index] = changedCartItem;
      }
    }

    setState(() {
      itemsOrdered--;
    });
  }

  //Get the menu from the resturant the user selected in the prior menu
  getRestaurantMenu() async {
    if (menuItems.isEmpty) {
      try {
        var response = await http.get(Uri.https(
            "private-anon-03ab229599-pizzaapp.apiary-mock.com",
            "/restaurants/" + restaurant.id.toString() + "/menu"));

        //use bodybytes decode to propperly parse accented characters
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));

        //Add items to the list of menu items by using the data from each entry in jsonData
        for (var i in jsonData) {
          Menu menu = Menu(
              id: i["id"] as int,
              category: i["category"] as String,
              name: i["name"] as String,
              toppings: i["topping"] as List<dynamic>?,
              price: i["price"] as int,
              rank: i["rank"] as int?);
          menuItems.add(menu);
        }

        //Sort the menu items by category
        menuItems.sort((a, b) => a.category.compareTo(b.category));
      } catch (e) {
        print(e);
      }
    }
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //Set up floating action button for navigating to the shopping list
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                //Open a new menu that shares the cartData from this page
                MaterialPageRoute(
                    builder: (context) =>
                        CartPage(populatedCart, restaurant, menuItems)));
          },
          //Create badge to show the user how many items they have added to their cart
          child: Badge(
            toAnimate: true,
            position: BadgePosition.topEnd(top: -20, end: -15),
            shape: BadgeShape.circle,
            badgeColor: Colors.orange,
            animationType: BadgeAnimationType.scale,
            animationDuration: const Duration(milliseconds: 500),
            borderRadius: BorderRadius.circular(100),
            badgeContent: Text(itemsOrdered.toString(),
                style: const TextStyle(color: Colors.white)),
            child: const Icon(
              Icons.shopping_cart,
            ),
          ),
        ),
        body: Container(
          //Set up future builder for getting the information from the server for the resturant menu
          child: FutureBuilder(
              future: getRestaurantMenu(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.data == null) {
                  return Container(
                    child: const Center(
                      child: Text("Loading..."),
                    ),
                  );
                } else {
                  //Use listview seperated to make it easier to see where the list items are seperated
                  return ListView.separated(
                      separatorBuilder: (context, index) {
                        return const Divider(
                          thickness: 2,
                        );
                      },
                      //Add padding to the bottom of the list so that the floating button doesn't cover the last entry
                      padding: const EdgeInsets.only(
                          bottom: kFloatingActionButtonMargin + 55),
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        //Set up string for what to display for the subtitle for each item
                        String subtitleText = "";

                        //If there are toppings, then display the toppings first in the subtitle
                        if (snapshot.data[index].toppings != null) {
                          subtitleText += "Toppings: \n";
                          for (String i in snapshot.data[index].toppings) {
                            subtitleText += i + "\n";
                          }
                        }

                        //Always show the price of each item
                        subtitleText += "Price: " +
                            snapshot.data[index].price.toString() +
                            " SEK";

                        //If the item has a rank, then display that rank with star emojis using a for loop
                        if (snapshot.data[index].rank != null) {
                          subtitleText += "\nRank: ";
                          for (int i = 1; i <= snapshot.data[index].rank; i++) {
                            subtitleText += "⭐";
                          }
                        }


                        //Set up funtionality to see of the item has a quantity of items added
                        int currentAmount = 0;

                        
                        Iterable<Cart> checkCart = populatedCart.where((element) => element.itemId == snapshot.data[index].id);

                        //If the cart entry exists, then update the badge value to match up with what is being recorded in the cart data
                        if(checkCart.isNotEmpty){
                          currentAmount = checkCart.first.quantity;
                        }

                        //Display the content in each list item from the strings constructed earlier
                        return ListTile(
                          leading: Badge(
                            toAnimate: true,
                            shape: BadgeShape.circle,
                            animationType: BadgeAnimationType.scale,
                            animationDuration:
                                const Duration(milliseconds: 500),
                            badgeContent: Text(currentAmount.toString(),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(snapshot.data[index].name,
                              style: GoogleFonts.notoSans()),
                          subtitle:
                              Text(subtitleText, style: GoogleFonts.notoSans()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //Buttons for adding and removing items from your shopping cart
                              IconButton(
                                  onPressed: () =>
                                      addToList(snapshot.data[index].id),
                                  icon: const Icon(Icons.add)),
                              IconButton(
                                  onPressed: () =>
                                      removeFromList(snapshot.data[index].id),
                                  icon: const Icon(Icons.remove)),
                            ],
                          ),
                        );
                      });
                }
              }),
        ));
  }
}
