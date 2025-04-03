import 'package:flutter/material.dart';
import 'home_page.dart';
import 'tracker_screen.dart';
import 'history_screen.dart';
import 'health_tips_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink, Colors.pinkAccent],
              ),
            ),
            child: Center(
              child: Text(
                'CycleCare Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.track_changes),
            title: Text('Tracker'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrackerScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('History'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.health_and_safety),
            title: Text('Health Tips'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HealthTipsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
