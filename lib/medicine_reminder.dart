// file: lib/medicine_reminder.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedicineReminderPage extends StatefulWidget {
  const MedicineReminderPage({Key? key}) : super(key: key);

  @override
  State<MedicineReminderPage> createState() => _MedicineReminderPageState();
}

class _MedicineReminderPageState extends State<MedicineReminderPage> {
  FlutterLocalNotificationsPlugin? _notifications;
  List<MedicineReminder> reminders = [];
  bool isLoading = true;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeNotifications();
    await _loadReminders();
  }

  Future<void> _initializeNotifications() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _notifications?.initialize(initializationSettings);
      
      // Request notification permissions
      final androidPlugin = _notifications
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
      
      _notificationsInitialized = true;
      print('✅ Notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      _notificationsInitialized = false;
    }
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('medicine_reminders') ?? [];
    
    setState(() {
      reminders = remindersJson
          .map((json) => MedicineReminder.fromJson(jsonDecode(json)))
          .toList();
      isLoading = false;
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = reminders
        .map((reminder) => jsonEncode(reminder.toJson()))
        .toList();
    await prefs.setStringList('medicine_reminders', remindersJson);
  }

  Future<void> _addReminder() async {
    final result = await showDialog<MedicineReminder>(
      context: context,
      builder: (context) => const AddReminderDialog(),
    );

    if (result != null) {
      setState(() {
        reminders.add(result);
      });
      await _saveReminders();
      
      // Only schedule notification if notifications are initialized
      if (_notificationsInitialized) {
        await _scheduleNotification(result);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder added for ${result.medicineName}'),
            backgroundColor: const Color(0xFF667eea),
          ),
        );
      }
    }
  }

  Future<void> _scheduleNotification(MedicineReminder reminder) async {
    if (!_notificationsInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications not initialized yet. Please wait a moment.'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
      }
      return;
    }

    // Check if notifications are enabled
    if (_notifications != null) {
      final androidPlugin = _notifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        if (areNotificationsEnabled == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications are disabled. Please enable them in settings.'),
                backgroundColor: Color(0xFFE53E3E),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }
    }

    try {
      print('🔔 Attempting to show notification for: ${reminder.medicineName}');
      
      // Create notification details with proper channel
      final androidDetails = AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders for taking medicine',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Time to take ${reminder.medicineName} (${reminder.dosage})',
          contentTitle: 'Medicine Reminder',
          htmlFormatBigText: true,
        ),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Show the notification
      await _notifications!.show(
        reminder.id.hashCode,
        'Medicine Reminder',
        'Time to take ${reminder.medicineName} (${reminder.dosage})',
        notificationDetails,
      );
      
      print('✅ Notification sent successfully');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification sent for ${reminder.medicineName}'),
            backgroundColor: const Color(0xFF667eea),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Notification error: $e');
      
      // Show error message if notification fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _testNotification(MedicineReminder reminder) {
    // Show a simple popup message instead of actual notification
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF667eea)),
            SizedBox(width: 8),
            Text('Test Reminder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is how your medicine reminder will look:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔔 Medicine Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Time to take your medicine!',
                    style: TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Medicine: ${reminder.medicineName}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                  ),
                  Text(
                    'Dosage: ${reminder.dosage}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MedicineReminder reminder) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete the reminder for ${reminder.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              _deleteReminder(reminder);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(MedicineReminder reminder) {
    setState(() {
      reminders.remove(reminder);
    });
    _saveReminders();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder deleted for ${reminder.medicineName}'),
        backgroundColor: const Color(0xFFE53E3E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3748),
      ),
      backgroundColor: const Color(0xFFF7FAFC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Card
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.medication,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Never Miss Your Medication',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set reminders to stay on track with your health',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Reminders List
                Expanded(
                  child: reminders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            return _buildReminderCard(reminder);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule,
              size: 64,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reminders Set',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first reminder',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(MedicineReminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.medicineName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.dosage} - ${_formatTime(reminder.hour, reminder.minute)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                    fontFamily: 'Inter',
                  ),
                ),
                if (reminder.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA0AEC0),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _testNotification(reminder),
                icon: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF667eea),
                ),
                tooltip: 'Test Reminder',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(reminder),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE53E3E),
                ),
                tooltip: 'Delete Reminder',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({Key? key}) : super(key: key);

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _noteController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Medicine Reminder',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 1 tablet, 2 capsules)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Reminder Time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveReminder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveReminder() {
    if (_medicineController.text.isEmpty || _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final reminder = MedicineReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: _medicineController.text,
      dosage: _dosageController.text,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      note: _noteController.text,
    );

    Navigator.of(context).pop(reminder);
  }
}

class MedicineReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final int hour;
  final int minute;
  final String note;

  MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'hour': hour,
      'minute': minute,
      'note': note,
    };
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'],
      medicineName: json['medicineName'],
      dosage: json['dosage'],
      hour: json['hour'],
      minute: json['minute'],
      note: json['note'],
    );
  }
}
