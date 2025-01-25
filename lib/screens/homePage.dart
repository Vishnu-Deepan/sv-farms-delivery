import 'package:flutter/material.dart';

import '../controller/homeLogic.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomePageLogic _logic;  // Create an instance of the logic class

  @override
  void initState() {
    super.initState();
    _logic = HomePageLogic(context, setState);  // Initialize logic
    _logic.initState();  // Call the initState of the logic class
  }

  @override
  void dispose() {
    _logic.dispose();  // Dispose logic
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: _logic.logout,
            icon: Icon(Icons.logout_rounded),
          ),
        ],
        title: const Text('SV Farms Delivery', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_logic.isDayStarted) ...[
              if (_logic.isStartButtonVisible )
                Center(
                  child: ElevatedButton(
                    onPressed: () => _logic.showConfirmationDialog('start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text(
                      _logic.startDeliveryButtonText,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
            if (_logic.isDayStarted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDashboardStat('Today\'s Deliveries', '${_logic.deliveriesToday}'),
                  _buildDashboardStat('Pending Deliveries', '${_logic.pendingDeliveries}'),
                  _buildDashboardStat('Delivered', '${_logic.delivered}'),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Today\'s Deliveries',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _logic.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _logic.deliveryQueue.isEmpty
                    ? Center(child: Text("No Deliveries Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))
                    : ListView.builder(
                  itemCount: _logic.deliveryQueue.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey[850],
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _logic.deliveryQueue[index]['name'],
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _logic.deliveryQueue[index]['address'],
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if ((_logic.deliveryQueue[index]['deliveryStatus'] == 'pending') && (_logic.deliveryQueue[index]['skipStatus'] == 'pending'))
                                      ElevatedButton.icon(
                                        onPressed: () => _logic.locateOnMap(index),
                                        icon: Icon(Icons.navigation_outlined, color: Colors.white),
                                        label: Text(
                                          'Open in\nGoogle Map',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                          backgroundColor: Colors.blueAccent,
                                          textStyle: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    if ((_logic.deliveryQueue[index]['deliveryStatus'] == 'completed') || (_logic.deliveryQueue[index]['skipStatus'] == 'completed')) ...[
                                      Icon(Icons.done_all, color: Colors.green, size: 30),
                                      const SizedBox(height: 8),
                                      Text('Completed', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            // Additional Button Handling for Completed/Skipped
                            if ((_logic.deliveryQueue[index]['deliveryStatus'] == 'pending') &&
                                (_logic.deliveryQueue[index]['skipStatus'] == 'pending')) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _logic.markAsCompleted(index),
                                    icon: Icon(Icons.check_circle, color: Colors.white),
                                    label: Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    _logic.deliveryQueue[index]['deliveryLitres'].toString(),
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _logic.markAsSkipped(index),
                                    icon: Icon(Icons.skip_next_outlined, color: Colors.white),
                                    label: Text(
                                      'Skipped',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      textStyle: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _logic.showConfirmationDialog('end'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: const Text(
                    'End Day',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
            if (!_logic.isStartButtonVisible) ...[
              Spacer(),
              Center(
                child: Text(
                  "Next Delivery Slot\nStarts in\n\n${_logic.timeRemaining}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Spacer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
