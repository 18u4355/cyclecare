import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app_drawer.dart';

class TrackerScreen extends StatefulWidget {
  @override
  _TrackerScreenState createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  String? _nextPeriodDate;
  List<String> _symptoms = [];
  String? userName;
  List<String> _dailyNotes = [];
  late TextEditingController _dailyNoteController;
  late TextEditingController _symptomController;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _dailyNoteController = TextEditingController();
    _symptomController = TextEditingController();
    _initializeNotifications();
    _loadUserData();
    _loadSavedData();
    _loadDailyNotes();
  }

  @override
  void dispose() {
    _dailyNoteController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  // Initialize local notifications and timezone.
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
    });
  }

  void _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String? savedDate = prefs.getString('lastPeriodDate');
      if (savedDate != null) {
        _lastPeriodDate = DateTime.parse(savedDate);
        _calculateNextPeriod();
      }
      _symptoms = prefs.getStringList('symptoms') ?? [];
      _cycleLength = prefs.getInt('cycleLength') ?? 28;
    });
  }

  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_lastPeriodDate != null) {
      await prefs.setString('lastPeriodDate', _lastPeriodDate!.toIso8601String());
      _calculateNextPeriod();
    }
    await prefs.setStringList('symptoms', _symptoms);
    await prefs.setInt('cycleLength', _cycleLength);
  }

  void _calculateNextPeriod() {
    if (_lastPeriodDate != null) {
      DateTime nextPeriod = _lastPeriodDate!.add(Duration(days: _cycleLength));
      setState(() {
        _nextPeriodDate = DateFormat('yyyy-MM-dd').format(nextPeriod);
      });
    }
  }

  void _addSymptom() {
    String symptom = _symptomController.text.trim();
    if (symptom.isNotEmpty) {
      setState(() {
        _symptoms.add(symptom);
        _saveData();
        _symptomController.clear();
      });
    }
  }

  void _deleteSymptom(int index) {
    setState(() {
      _symptoms.removeAt(index);
      _saveData();
    });
  }

  void _loadDailyNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyNotes = prefs.getStringList('dailyNotes') ?? [];
    });
  }

  void _saveDailyNote() async {
    String noteText = _dailyNoteController.text.trim();
    if (noteText.isNotEmpty) {
      String timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      String fullNote = '$timestamp: $noteText';
      setState(() {
        _dailyNotes.add(fullNote);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dailyNotes', _dailyNotes);
      _dailyNoteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily note saved!')),
      );
    }
  }

  void _deleteDailyNote(int index) {
    setState(() {
      _dailyNotes.removeAt(index);
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('dailyNotes', _dailyNotes);
    });
  }

  // Updated: Use StatefulBuilder for the reminder dialog so that the slider moves.
  void _openReminderDialog() {
    int offsetDays = 1; // default offset
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Set Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Remind me how many days before my next period?'),
                  Slider(
                    value: offsetDays.toDouble(),
                    min: 0,
                    max: 7,
                    divisions: 7,
                    label: '$offsetDays days',
                    onChanged: (value) {
                      setStateDialog(() {
                        offsetDays = value.toInt();
                      });
                    },
                  ),
                  Text('$offsetDays day(s) before'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _scheduleReminder(offsetDays);
                  },
                  child: Text('Set Reminder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleReminder(int offsetDays) async {
    if (_nextPeriodDate == null || _lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set your period date first.')),
      );
      return;
    }
    DateTime predictedDate = DateTime.parse(_nextPeriodDate!);
    DateTime reminderTime = predictedDate.subtract(Duration(days: offsetDays));
    if (reminderTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The reminder time has already passed.')),
      );
      return;
    }
    var androidDetails = AndroidNotificationDetails(
      'cyclecare_channel',
      'CycleCare Reminders',
      channelDescription: 'Reminders for upcoming periods',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iosDetails = DarwinNotificationDetails();
    var notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    // Convert reminderTime to a timezone-aware time.
    tz.TZDateTime tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    
    await _flutterLocalNotificationsPlugin!.zonedSchedule(
      0,
      'CycleCare Reminder',
      'Your next period is coming in $offsetDays day(s)!',
      tzReminderTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${DateFormat('yyyy-MM-dd – kk:mm').format(reminderTime)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cycleProgress = 0.0;
    int daysPassed = 0;
    if (_lastPeriodDate != null) {
      daysPassed = DateTime.now().difference(_lastPeriodDate!).inDays;
      cycleProgress = daysPassed / _cycleLength;
      if (cycleProgress > 1.0) cycleProgress = 1.0;
    }

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Cycle Tracker for ${userName ?? "User"}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Period Date & Cycle Length Card
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        userName != null
                            ? 'Hi, $userName! Select your last period date:'
                            : 'Select your last period date:',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text('Pick Date'),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _lastPeriodDate = pickedDate;
                              _saveData();
                            });
                          }
                        },
                      ),
                      SizedBox(height: 10),
                      if (_lastPeriodDate != null)
                        Text(
                          'Last period: ${DateFormat('yyyy-MM-dd').format(_lastPeriodDate!)}',
                        ),
                      if (_nextPeriodDate != null)
                        Text(
                          'Next predicted period: $_nextPeriodDate',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      SizedBox(height: 20),
                      Text(
                        'Cycle Length: $_cycleLength days',
                        style: TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: _cycleLength.toDouble(),
                        min: 20,
                        max: 40,
                        divisions: 20,
                        label: '$_cycleLength',
                        onChanged: (value) {
                          setState(() {
                            _cycleLength = value.toInt();
                            _saveData();
                          });
                        },
                      ),
                      if (_lastPeriodDate != null)
                        Column(
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Cycle Progress: Day ${daysPassed.clamp(0, _cycleLength)} of $_cycleLength',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            CircularProgressIndicator(
                              value: cycleProgress,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Symptoms Card
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Symptoms', style: TextStyle(fontSize: 18)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _symptomController,
                              decoration: InputDecoration(
                                labelText: 'Enter Symptom',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addSymptom,
                            child: Text('Save'),
                            style: ElevatedButton.styleFrom(iconColor: Colors.pink),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _symptoms.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: _symptoms.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_symptoms[index]),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSymptom(index),
                                  ),
                                );
                              },
                            )
                          : Text('No symptoms added yet'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Daily Note Card with saved notes list
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Note', style: TextStyle(fontSize: 18)),
                      TextField(
                        controller: _dailyNoteController,
                        decoration: InputDecoration(
                          labelText: 'How do you feel today?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: null,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Save Note'),
                        onPressed: _saveDailyNote,
                        style: ElevatedButton.styleFrom(
                          iconColor: Colors.pink,
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Saved Daily Notes:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      _dailyNotes.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _dailyNotes.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_dailyNotes[index]),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDailyNote(index),
                                  ),
                                );
                              },
                            )
                          : Text('No daily notes saved yet.'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Redesigned Reminder Button
              ElevatedButton.icon(
                icon: Icon(Icons.alarm, size: 28),
                label: Text(
                  'Set Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _openReminderDialog,
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.pink,
                  shadowColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
