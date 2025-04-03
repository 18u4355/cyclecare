import 'package:flutter/material.dart';
import 'app_drawer.dart';

class HealthTipsScreen extends StatelessWidget {
  final List<String> healthTips = [
    'Maintain a balanced diet to support hormonal balance.',
    'Regular exercise can help reduce menstrual discomfort.',
    'Stay hydrated and get enough sleep during your cycle.',
    'Manage stress through relaxation techniques or yoga.',
    'Consult a healthcare provider if you experience irregular cycles.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Health Tips'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: healthTips.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.health_and_safety, color: Colors.pinkAccent),
                title: Text(healthTips[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
