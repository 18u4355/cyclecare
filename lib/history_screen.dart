import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_drawer.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DateTime> _periodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = prefs.getStringList('periodHistory') ?? [];
    setState(() {
      _periodHistory = historyStrings.map((dateStr) => DateTime.parse(dateStr)).toList();
      _periodHistory.sort((a, b) => b.compareTo(a));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Cycle History'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _periodHistory.isNotEmpty
            ? ListView.builder(
                itemCount: _periodHistory.length,
                itemBuilder: (context, index) {
                  DateTime date = _periodHistory[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.pinkAccent),
                      title: Text(DateFormat('yyyy-MM-dd').format(date)),
                    ),
                  );
                },
              )
            : Center(child: Text('No period history available.')),
      ),
    );
  }
}
