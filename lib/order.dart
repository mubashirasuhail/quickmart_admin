/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetails extends StatefulWidget {
  const OrderDetails({super.key});

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _firestore
        .collection('order') // Ensure correct collection name
        .snapshots();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('order')
          .doc(orderId)
          .update({'orderStatus': newStatus}); // Ensure correct collection name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot<Map<String, dynamic>> orderDoc =
                  snapshot.data!.docs[index];
              Order order = Order.fromFirestore(orderDoc);
              String formattedDate =
                  DateFormat('yyyy-MM-dd – kk:mm').format(order.orderDate);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: ${order.orderId}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Order Date: $formattedDate',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Address: ${order.address}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Payment Method: ${order.paymentMethod}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ₹${order.totalAmount?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Order Status: ${order.orderStatus}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print(
                                  "Updating order with ID: ${order.orderId}"); // Add this line
                              _updateOrderStatus(order.orderId, 'Accepted');
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text('Accept',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _updateOrderStatus(order.orderId, 'Rejected'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Reject',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _updateOrderStatus(order.orderId, 'Delivered'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow),
                            child: const Text('Delivered',
                                style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Order {
  String orderId;
  String address;
  String paymentMethod;
  double? totalAmount;
  DateTime orderDate;
  String orderStatus;

  Order({
    required this.orderId,
    required this.address,
    required this.paymentMethod,
    this.totalAmount,
    required this.orderDate,
    required this.orderStatus,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return Order(
        orderId: '',
        address: '',
        paymentMethod: '',
        totalAmount: 0.0,
        orderDate: DateTime.now(),
        orderStatus: '',
      );
    }

    String orderId = doc.id;
    if (orderId.startsWith('COD-')) {
      orderId = orderId.substring(4);
    } else if (orderId.startsWith('pay-')) {
      orderId = orderId.substring(4);
    }

    dynamic orderDateData = data['orderDate'];
    DateTime? orderDate;

    if (orderDateData is Timestamp) {
      orderDate = orderDateData.toDate();
    } else if (orderDateData is String) {
      orderDate = DateTime.tryParse(orderDateData);
      if (orderDate == null) {
        print(
            "Warning: Could not parse orderDate String: $orderDateData for order ID: ${doc.id}");
        orderDate = DateTime.now();
      }
    } else {
      orderDate = DateTime.now();
    }

    return Order(
      orderId: orderId,
      address: data['address'] ?? '', // Retrieve address from Firestore
      paymentMethod: data['paymentMethod'] ?? '',
      totalAmount: data['totalAmount'] is String
          ? double.tryParse(data['totalAmount'])
          : data['totalAmount']?.toDouble(),
      orderDate: orderDate ?? DateTime.now(),
      orderStatus: data['orderStatus'] ?? '',
    );
  }

  Map<String, dynamic> get toFirestore => {
        'orderId': orderId,
        'address': address,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'orderDate': orderDate,
        'orderStatus': orderStatus,
      };
}
*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetails extends StatefulWidget {
  const OrderDetails({super.key});

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String fullFirestoreDocumentId, String newStatus) async {
    print('Attempting to update order with Full Firestore Document ID: $fullFirestoreDocumentId to status: $newStatus');
    try {
      await _firestore
          .collection('order')
          .doc(fullFirestoreDocumentId)
          .update({'orderStatus': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
      print('Update successful for Order Document ID: $fullFirestoreDocumentId');

      // If the order is accepted from the rejected tab, switch to New Orders tab
      // This logic already exists and is kept.
      if (newStatus == 'Accepted') {
        _tabController.animateTo(0); // Index 0 is 'New Orders'
      }

    } catch (e) {
      print('!!! ERROR updating order status for Order Document ID: $fullFirestoreDocumentId. Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  Stream<List<Order>> _getOrdersByStatus(List<String> statuses) {
    return _firestore
        .collection('order')
        .where('orderStatus', whereIn: statuses)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  /// Helper function to format payment method capitalization.
  /// Formats 'cod' to 'COD' and 'credit_card' to 'Credit Card'.
  String _formatPaymentMethod(String method) {
    String cleanedMethod = method.trim().toLowerCase();
    switch (cleanedMethod) {
      case 'cod':
        return 'COD'; // Full capital letters for Cash on Delivery
      case 'credit_card':
        return 'Credit Card'; // First letter capitalized
      // Add other payment methods as needed
      default:
        return method; // Return as-is if not recognized
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Orders'), // Index 0: 'Placed', 'Accepted'
            Tab(text: 'Rejected'),    // Index 1: 'Rejected'
            Tab(text: 'Delivered'),   // Index 2: 'Delivered'
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // New Orders tab: shows 'Placed' and 'Accepted' orders with action buttons
          _buildOrderList(['Placed', 'Accepted']),
          // Rejected tab: shows 'Rejected' orders with an 'Accept' button if needed
          _buildOrderList(['Rejected']),
          // Delivered tab: shows 'Delivered' orders with no action buttons
          _buildOrderList(['Delivered']),
        ],
      ),
    );
  }

  /// Builds a list of orders based on the given statuses.
  /// Action buttons are dynamically generated based on order status within _buildActionButtons.
  Widget _buildOrderList(List<String> statuses) {
    return StreamBuilder<List<Order>>(
      stream: _getOrdersByStatus(statuses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Stream error for statuses $statuses: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('No ${statuses.join(' or ')} orders found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            Order order = snapshot.data![index];
            // Format date to 'dd-MM-yyyy – hh:mm AM/PM'
            String formattedDate = DateFormat('dd-MM-yyyy – hh:mm a').format(order.orderDate);
            // Format payment method using the helper function
            String formattedPaymentMethod = _formatPaymentMethod(order.paymentMethod);

            // Determine status text color based on order status
            Color statusColor;
            switch (order.orderStatus.toLowerCase()) {
              case 'rejected':
                statusColor = Colors.red;
                break;
              case 'delivered':
                statusColor = Colors.green;
                break;
              case 'accepted': // Accepted and Placed will be blue
              case 'placed':
                statusColor = Colors.blue;
                break;
              default:
                statusColor = Colors.black;
            }


            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: ${order.orderId}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Order Date: $formattedDate',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Address: ${order.address}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    // Display the formatted payment method
                    Text('Payment Method: $formattedPaymentMethod',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Total Amount: ₹${order.totalAmount?.toStringAsFixed(2) ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    // Display order status with dynamic color
                    Text('Order Status: ${order.orderStatus}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                    const SizedBox(height: 16),
                    // Dynamically build action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildActionButtons(order),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds a list of action buttons based on the order's current status.
  List<Widget> _buildActionButtons(Order order) {
    List<Widget> buttons = [];

    // 'New Orders' Tab (statuses: 'Placed', 'Accepted')
    if (order.orderStatus == 'Placed') {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _updateOrderStatus(order.fullDocumentId, 'Accepted');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Accept', style: TextStyle(color: Colors.white)),
        ),
      );
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _updateOrderStatus(order.fullDocumentId, 'Rejected');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject', style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (order.orderStatus == 'Accepted') {
      // Show 'Delivered' button if already Accepted
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _updateOrderStatus(order.fullDocumentId, 'Delivered');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
          child: const Text('Delivered', style: TextStyle(color: Colors.black)),
        ),
      );
    }
    // 'Rejected' Tab (status: 'Rejected')
    else if (order.orderStatus == 'Rejected') {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _updateOrderStatus(order.fullDocumentId, 'Accepted');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Accept', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    // 'Delivered' Tab (status: 'Delivered') will have no buttons

    return buttons;
  }
}

class Order {
  String orderId;
  String fullDocumentId;
  String address;
  String paymentMethod;
  double? totalAmount;
  DateTime orderDate;
  String orderStatus;

  Order({
    required this.orderId,
    required this.fullDocumentId,
    required this.address,
    required this.paymentMethod,
    this.totalAmount,
    required this.orderDate,
    required this.orderStatus,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return Order(
        orderId: doc.id,
        fullDocumentId: doc.id,
        address: 'N/A',
        paymentMethod: 'N/A',
        totalAmount: 0.0,
        orderDate: DateTime.now(),
        orderStatus: 'Unknown',
      );
    }

    String actualFullDocumentId = doc.id;
    String displayOrderId = doc.id;

    if (displayOrderId.startsWith('COD-')) {
      displayOrderId = displayOrderId.substring(4);
    } else if (displayOrderId.startsWith('pay-')) {
      displayOrderId = displayOrderId.substring(4);
    }

    dynamic orderDateData = data['orderDate'];
    DateTime? orderDate;

    if (orderDateData is Timestamp) {
      orderDate = orderDateData.toDate();
    } else if (orderDateData is String) {
      orderDate = DateTime.tryParse(orderDateData);
      if (orderDate == null) {
        print("Warning: Could not parse orderDate String: $orderDateData for order ID: ${doc.id}");
        orderDate = DateTime.now();
      }
    } else {
      orderDate = DateTime.now();
    }

    double? parsedTotalAmount;
    if (data['totalAmount'] is String) {
      parsedTotalAmount = double.tryParse(data['totalAmount']);
    } else if (data['totalAmount'] is num) {
      parsedTotalAmount = data['totalAmount'].toDouble();
    }

    return Order(
      orderId: displayOrderId,
      fullDocumentId: actualFullDocumentId,
      address: data['address'] ?? 'N/A',
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      totalAmount: parsedTotalAmount,
      orderDate: orderDate ?? DateTime.now(),
      orderStatus: data['orderStatus'] ?? 'Placed',
    );
  }

  Map<String, dynamic> get toFirestore => {
        'address': address,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'orderDate': orderDate,
        'orderStatus': orderStatus,
      };
}