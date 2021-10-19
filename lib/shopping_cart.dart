import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pizza_order_app/model/cart.dart';
import 'package:pizza_order_app/model/menu.dart';
import 'package:pizza_order_app/model/order.dart';
import 'package:pizza_order_app/model/restaurants.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CartPage extends StatelessWidget {
  List<Cart> cart;
  Restaurants restaurant;
  List<Menu> menuItems;

  CartPage(this.cart, this.restaurant, this.menuItems);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Cart"),
      ),
      body: Center(
        child: MyCartPage(cart, restaurant, menuItems),
      ),
    );
  }
}

class MyCartPage extends StatefulWidget {
  List<Cart> cart;
  Restaurants restaurant;
  List<Menu> menuItems;

  MyCartPage(this.cart, this.restaurant, this.menuItems);

  @override
  State<MyCartPage> createState() =>
      _MyCartPageState(cart, restaurant, menuItems);
}

class _MyCartPageState extends State<MyCartPage> {
  List<Cart> cart;
  Restaurants restaurant;
  List<Menu> menuItems;

  _MyCartPageState(this.cart, this.restaurant, this.menuItems);

  List<String> orderList = [];
  List<int> priceList = [];

  @override
  void initState() {
    //Put together the list of all the items the user ordered
    assembleData();
  }

  //Return the string for the popup menu
  String orderStatus(Order orderStatus){
    //Display final price of the order
    String status = "Total Price: " + orderStatus.totalPrice.toString() + " SEK";
    
    //Parse the strings to later format the date
    DateTime orderedAt = DateTime.parse(orderStatus.orderedAt);
    DateTime deliverAt = DateTime.parse(orderStatus.estimatedDelivery);

    //Format the dates and display the current status of the order
    status += "\nOrdered on: " + DateFormat(DateFormat.HOUR24_MINUTE).format(orderedAt);
    status +="\nEstimated Delivery at: " + DateFormat(DateFormat.HOUR24_MINUTE).format(deliverAt);
    status += "\nOrder Status: " + orderStatus.status;

    return status;
  }

  //Send a request to the json server using the cart data to obtain the order status
  sendJson() async{
    if(cart.isEmpty){
      showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text("Please select items to make a purchase"),
      ), barrierDismissible: true);
      return;
    }
    print("Message sent");

    try{
      var response = await http.post(
        Uri.parse("https://private-anon-03ab229599-pizzaapp.apiary-mock.com/orders/"),
        body: {"cart": cart.toString(), "restuarantId": restaurant.id.toString()}
      );
      print(response.body);

       var jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      //Add items to the list of menu items by using the data from each entry in jsonData
      Order order = Order(
        orderId: jsonData["orderId"],
        totalPrice: jsonData["totalPrice"],
        orderedAt: jsonData["orderedAt"],
        estimatedDelivery: jsonData["esitmatedDelivery"],
        status: jsonData["status"]
        );




      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Purchase confirmed"),
        content: Text(orderStatus(order)),
        actions: [
          TextButton(
            //Return to the home screen after viewing the order status
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Return")),
        ],
      ), barrierDismissible: false);
    }
    catch(e){
      print(e);
    }
  }

  assembleData() {
    for (Cart i in cart) {
      String entry = "";
      Menu menuItem = menuItems.firstWhere((element) => element.id == i.itemId);

      entry += i.quantity.toString() + " ";
      entry += menuItem.name;

      int price = menuItem.price * i.quantity;

      orderList.add(entry);
      priceList.add(price);
    }

    orderList.add("Total");

    int totalPrice = 0;

    for (int i in priceList) {
      totalPrice += i;
    }
    priceList.add(totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          label: const Text("Purchase items"),
          onPressed: () => sendJson(),
          ),
        body: Container(
      child: ListView.builder(
        itemCount: orderList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(orderList[index]),
            trailing: Text(priceList[index].toString() + " SEK"),
          );
        },
      ),
    ));
  }
}
