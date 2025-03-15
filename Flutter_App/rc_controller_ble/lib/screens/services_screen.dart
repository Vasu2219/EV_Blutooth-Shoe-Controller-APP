import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.upcoming, color: Colors.blue, size: 30),
              SizedBox(width: 10),
              Text(
                'Coming Soon!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$feature is under development.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Live Speed Tracking',
        'description': 'Shows real-time speed (km/h or mph)',
        'icon': Icons.speed,
      },
      {
        'title': 'Distance Travelled',
        'description': 'Logs total distance covered',
        'icon': Icons.route,
      },
      {
        'title': 'Battery/Power Consumption',
        'description': 'Displays power usage and efficiency',
        'icon': Icons.battery_charging_full,
      },
      {
        'title': 'Weight Detection',
        'description': 'Uses pressure sensors to measure user weight',
        'icon': Icons.monitor_weight,
      },
      {
        'title': 'Remote Control',
        'description': 'Adjusts speed & direction via the app',
        'icon': Icons.gamepad,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Services'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hardware Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported Hardware',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ESP32 Card
                      Card(
                        color: Colors.black.withOpacity(0.6),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/esp32.png',
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ESP32',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Raspberry Pi Card
                      Card(
                        color: Colors.black.withOpacity(0.6),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/Rasberry.png',
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Raspberry Pi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            // Features List
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...features.map((feature) => Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        feature['icon'] as IconData,
                        color: Colors.blue,
                        size: 32,
                      ),
                      title: Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        feature['description'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      onTap: () {
                        if (feature['title'] == 'Remote Control') {
                          context.go('/home');
                        } else {
                          _showComingSoonDialog(context, feature['title'] as String);
                        }
                      },
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 