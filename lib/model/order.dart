//Class used for displaying order information

class Order{
  int orderId;
  int totalPrice;
  String orderedAt;
  String estimatedDelivery;
  String status;
  
  
  Order(
    {required this.orderId, required this.totalPrice, required this.orderedAt, required this.estimatedDelivery, required this.status}
  );
}