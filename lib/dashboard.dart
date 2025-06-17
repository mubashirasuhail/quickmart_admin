import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:math';

import 'package:quick_mart_admin/color.dart'; // For random number generation

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<FlSpot> _orderSpots = [];
  List<PieChartSectionData> _orderStatusSections = [];
  List<BarChartGroupData> _topProductsBars = [];
  List<String> _productNamesForBars = []; // To store product names for X-axis labels

  bool _isLoading = true; // Still useful for initial data generation delay simulation
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateAllMockData(); // Generate all mock data
  }

  void _generateAllMockData() {
    // Simulate a small delay for data generation
    Future.delayed(const Duration(milliseconds: 500), () {
      // Orders over time (daily data for the last 30 days)
      final List<Map<String, dynamic>> dailyOrders =
          List.generate(30, (i) {
        final date = DateTime.now().subtract(Duration(days: 29 - i));
        return {
          'date': DateFormat('MMM dd').format(date),
          'orders': _random.nextInt(150) + 50, // 50-200 orders per day
        };
      });

      _orderSpots = dailyOrders.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value['orders'].toDouble());
      }).toList();

      // Order status distribution based on statuses: "placed", "accepted", "rejected", "delivered"
      final Map<String, int> statusCounts = {
        'Placed': _random.nextInt(40) + 10,  // 10-50 placed orders
        'Accepted': _random.nextInt(60) + 20, // 20-80 accepted orders
        'Delivered': _random.nextInt(100) + 50, // 50-150 delivered orders
        'Rejected': _random.nextInt(15) + 5,   // 5-20 rejected orders
      };

      final List<Color> pieColors = [
        Colors.orange.shade600, // Placed
        Colors.blue.shade600,   // Accepted
        Colors.teal.shade600,   // Delivered
        Colors.red.shade600,    // Rejected
      ];

      final List<PieChartSectionData> newOrderStatusSections = [];
      int index = 0;
      statusCounts.forEach((status, count) {
        newOrderStatusSections.add(
          PieChartSectionData(
            color: pieColors[index % pieColors.length],
            value: count.toDouble(),
            title: '${count}\n$status',
            radius: index == 0 ? 60 : 50, // Emphasize first slice slightly
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.55,
          ),
        );
        index++;
      });

      // Top selling products
      final List<Map<String, dynamic>> products = [
        {'name': 'Organic Apples', 'sales': _random.nextInt(500) + 100},
        {'name': 'Whole Wheat Bread', 'sales': _random.nextInt(400) + 80},
        {'name': 'Fresh Milk (1L)', 'sales': _random.nextInt(350) + 70},
        {'name': 'Avocado (Each)', 'sales': _random.nextInt(300) + 60},
        {'name': 'Chicken Breast (500g)', 'sales': _random.nextInt(250) + 50},
      ];
      products.sort((a, b) => b['sales'].compareTo(a['sales'])); // Sort by sales
      final List<Map<String, dynamic>> topProducts = products.take(5).toList();

      final List<String> newProductNamesForBars = topProducts.map((p) => p['name'] as String).toList();

      final List<BarChartGroupData> newTopProductsBars = topProducts.indexed.map((entry) {
        final int barIndex = entry.$1;
        final Map<String, dynamic> product = entry.$2;
        return BarChartGroupData(
          x: barIndex,
          barRods: [
            BarChartRodData(
              toY: product['sales'].toDouble(),
              color: Colors.orange.shade600,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
        );
      }).toList();

      setState(() {
        _orderSpots = dailyOrders.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value['orders'].toDouble())).toList();
        _orderStatusSections = newOrderStatusSections;
        _topProductsBars = newTopProductsBars;
        _productNamesForBars = newProductNamesForBars;
        _isLoading = false;
      });
    });
  }

  // Helper widget to build individual stat cards
  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Card(
      color: bgColor,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Added Expanded to give the title text flexible space
                  child: FittedBox( // Wrapped title text in FittedBox
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1, // Ensure title stays on one line
                      overflow: TextOverflow.ellipsis, // Add ellipsis if text still overflows
                    ),
                  ),
                ),
                Icon(icon, color: iconColor, size: 32),
              ],
            ),
            const SizedBox(height: 8),
            // Changed: Wrapped value Text in FittedBox to prevent overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 32, // Max font size, will scale down if needed
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
                maxLines: 1, // Ensure it stays on one line
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total and specific status counts for cards based on new statuses
    final int totalOrders = _orderSpots.fold(0, (sum, spot) => sum + spot.y.toInt());
    final int placedOrders = _orderStatusSections
        .firstWhere((element) => element.title!.contains('Placed'), orElse: () => PieChartSectionData(value: 0))
        .value
        .toInt();
    final int acceptedOrders = _orderStatusSections
        .firstWhere((element) => element.title!.contains('Accepted'), orElse: () => PieChartSectionData(value: 0))
        .value
        .toInt();
    final int deliveredOrders = _orderStatusSections
        .firstWhere((element) => element.title!.contains('Delivered'), orElse: () => PieChartSectionData(value: 0))
        .value
        .toInt();
    final int rejectedOrders = _orderStatusSections
        .firstWhere((element) => element.title!.contains('Rejected'), orElse: () => PieChartSectionData(value: 0))
        .value
        .toInt();


    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading QuickMart Dashboard Data...'),
            ],
          ),
        ),
      );
    }

    // No error handling needed if not fetching from Firebase
    // if (_errorMessage.isNotEmpty) {
    //   return Scaffold(
    //     body: Center(
    //       child: Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Icon(Icons.error_outline, color: Colors.red, size: 60),
    //             SizedBox(height: 16),
    //             Text(
    //               'Error: $_errorMessage',
    //               textAlign: TextAlign.center,
    //               style: TextStyle(color: Colors.red.shade700, fontSize: 16),
    //             ),
    //             SizedBox(height: 16),
    //             ElevatedButton(
    //               onPressed: () {
    //                 setState(() {
    //                   _isLoading = true;
    //                   _errorMessage = '';
    //                 });
    //                 _generateAllMockData(); // Retry mock data generation
    //               },
    //               child: const Text('Retry'),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.darkgreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'QuickMart Admin Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          //  color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickMart Admin Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Overview of Order Details and Key Metrics',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjust number of columns based on screen width
                int crossAxisCount = 2;
                if (constraints.maxWidth > 900) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 600) {
                  crossAxisCount = 2;
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Important to disable inner scrolling
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.2, // Adjusted for slightly wider cards
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Orders', // Simplified title
                      totalOrders.toString(),
                      Icons.shopping_cart_rounded,
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                    _buildStatCard(
                      'Placed Orders',
                      placedOrders.toString(),
                      Icons.pending_actions_rounded,
                      Colors.amber.shade600,
                      Colors.amber.shade50,
                    ),
                    _buildStatCard(
                      'Accepted Orders',
                      acceptedOrders.toString(),
                      Icons.check_circle_outline_rounded,
                      Colors.blue.shade600,
                      Colors.blue.shade50,
                    ),
                    _buildStatCard(
                      'Delivered Orders',
                      deliveredOrders.toString(),
                      Icons.check_circle_rounded,
                      Colors.teal.shade600,
                      Colors.teal.shade50,
                    ),
                     _buildStatCard(
                      'Rejected Orders', // New card for Rejected
                      rejectedOrders.toString(),
                      Icons.cancel_rounded, // Icon for rejected orders
                      Colors.red.shade600,
                      Colors.red.shade50,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Graphs Section
            // Orders Over Time Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.show_chart_rounded, color: Colors.blue.shade500),
                        const SizedBox(width: 8),
                        const Text(
                          'Orders Over Time',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  // Display date labels every 7 days for readability
                                  final int index = value.toInt();
                                  if (index % 7 == 0 && index < _orderSpots.length) {
                                    final date = DateTime.now().subtract(Duration(days: _orderSpots.length - 1 - index));
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4,
                                      child: Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                    );
                                  }
                                  return Container();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _orderSpots,
                              isCurved: true,
                              color: Colors.green.shade500,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: Colors.green.shade500.withOpacity(0.3)),
                            ),
                          ],
                          minY: 0,
                          lineTouchData: const LineTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Status Distribution Chart and Top Selling Products Chart
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  // Two columns for larger screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildOrderStatusChart()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTopSellingProductsChart()),
                    ],
                  );
                } else {
                  // Single column for smaller screens
                  return Column(
                    children: [
                      _buildOrderStatusChart(),
                      const SizedBox(height: 24),
                      _buildTopSellingProductsChart(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: Colors.purple.shade500),
                const SizedBox(width: 8),
                const Text(
                  'Order Status Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _orderStatusSections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        return;
                      }
                      // You can add interaction logic here if needed (e.g., show details)
                    });
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingProductsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_rounded, color: Colors.orange.shade500),
                const SizedBox(width: 8),
                const Text(
                  'Top Selling Products',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: _topProductsBars,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60, // Adjust as needed for long labels
                        getTitlesWidget: (value, meta) {
                          final String productName = _productNamesForBars[value.toInt()];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Transform.rotate(
                              angle: -0.7, // Rotate text for better readability
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                productName,
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
