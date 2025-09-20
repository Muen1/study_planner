import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Make sure this import is added

void main() {
  runApp(StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.pink,
          secondary: Color(0xFFAEC6CF),
        ),
        scaffoldBackgroundColor: Color(0xFFFFF0F5),
        fontFamily: 'ComicNeue',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF6A5ACD)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFD1DC),
          titleTextStyle: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 24,
            color: Color(0xFF6A5ACD),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFB5EAD7),
          foregroundColor: Color(0xFF6A5ACD),
        ),
      ),
      home: MainScreen(),
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  DateTime? reminderTime;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.description = '',
    this.reminderTime,
    this.isCompleted = false,
  });

  // Convert Task to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // Create a Task from a Map (from JSON)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime']) : null,
      isCompleted: map['isCompleted'],
    );
  }
}

class TaskManager {
  static const String _tasksKey = 'tasks';

  // Get all tasks from storage
  Future<List<Task>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tasksString = prefs.getString(_tasksKey) ?? '[]';
      final List<dynamic> tasksList = json.decode(tasksString);
      return tasksList.map((taskMap) => Task.fromMap(taskMap)).toList();
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  // Save all tasks to storage
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tasksString = json.encode(tasks.map((task) => task.toMap()).toList());
      await prefs.setString(_tasksKey, tasksString);
      print('Tasks saved successfully: ${tasks.length} tasks');
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    final List<Task> tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  // Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    final List<Task> tasks = await getTasks();
    final int index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final List<Task> tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  // Clear all tasks
  Future<void> clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final TaskManager _taskManager = TaskManager();
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Initialize screens with task manager
    _screens.addAll([
      TodayScreen(taskManager: _taskManager),
      CalendarScreen(taskManager: _taskManager),
      SettingsScreen(taskManager: _taskManager),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.today, color: Color(0xFF6A5ACD)),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, color: Color(0xFF6A5ACD)),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Color(0xFF6A5ACD)),
            label: 'Settings',
          ),
        ],
        backgroundColor: Color(0xFFFFD1DC),
        selectedItemColor: Color(0xFF6A5ACD),
        unselectedItemColor: Color(0xFFAEC6CF),
      ),
    );
  }
}

class TodayScreen extends StatefulWidget {
  final TaskManager taskManager;

  TodayScreen({required this.taskManager});

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<Task> _todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final allTasks = await widget.taskManager.getTasks();
    final today = DateTime.now();
    setState(() {
      _todayTasks = allTasks.where((task) {
        return task.dueDate.year == today.year &&
            task.dueDate.month == today.month &&
            task.dueDate.day == today.day;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Tasks'),
        centerTitle: true,
      ),
      body: _todayTasks.isEmpty
          ? Center(
              child: Text(
                'No tasks for today!\nEnjoy your day ☺️',
                style: TextStyle(fontSize: 18, color: Color(0xFF6A5ACD)),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _todayTasks.length,
              itemBuilder: (context, index) {
                final task = _todayTasks[index];
                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await widget.taskManager.deleteTask(task.id);
                    _loadTasks(); // Reload tasks after deletion
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Color(0xFFF0E6FF),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          color: Color(0xFF6A5ACD),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: task.description.isNotEmpty
                          ? Text(
                              task.description,
                              style: TextStyle(color: Color(0xFF6A5ACD).withOpacity(0.7)),
                            )
                          : null,
                      trailing: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) async {
                          setState(() {
                            task.isCompleted = value!;
                          });
                          await widget.taskManager.updateTask(task);
                        },
                        activeColor: Color(0xFFB5EAD7),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen(taskManager: widget.taskManager)),
          ).then((value) => _loadTasks());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final TaskManager taskManager;

  CalendarScreen({required this.taskManager});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() async {
    final tasks = await widget.taskManager.getTasks();
    setState(() {
      _events = {};
      for (var task in tasks) {
        final day = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        if (_events[day] == null) {
          _events[day] = [];
        }
        _events[day]!.add(task);
      }
    });
  }

  List<Task> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Calendar'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color(0xFFB5EAD7),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFFFFD1DC),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Color(0xFFAEC6CF),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF6A5ACD),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF6A5ACD)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF6A5ACD)),
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text('Select a day to view tasks'))
                : _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay!);
    return events.isEmpty
        ? Center(
            child: Text(
              'No tasks for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
              style: TextStyle(color: Color(0xFF6A5ACD)),
            ),
          )
        : ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final task = events[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Color(0xFFF0E6FF),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      color: Color(0xFF6A5ACD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: task.description.isNotEmpty
                      ? Text(
                          task.description,
                          style: TextStyle(color: Color(0xFF6A5ACD).withOpacity(0.7)),
                        )
                      : null,
                  trailing: Text(
                    DateFormat('HH:mm').format(task.dueDate),
                    style: TextStyle(color: Color(0xFF6A5ACD)),
                  ),
                ),
              );
            },
          );
  }
}

class SettingsScreen extends StatefulWidget {
  final TaskManager taskManager;

  SettingsScreen({required this.taskManager});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A5ACD),
              ),
            ),
            SwitchListTile(
              title: Text('Enable Reminders', style: TextStyle(color: Color(0xFF6A5ACD))),
              value: _remindersEnabled,
              onChanged: (value) {
                setState(() {
                  _remindersEnabled = value;
                });
              },
              activeColor: Color(0xFFB5EAD7),
            ),
            SizedBox(height: 20),
            Text(
              'Storage Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A5ACD),
              ),
            ),
            ListTile(
              title: Text('Storage Method', style: TextStyle(color: Color(0xFF6A5ACD))),
              subtitle: Text('Shared Preferences', style: TextStyle(color: Color(0xFF6A5ACD))),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.taskManager.clearAllTasks();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared'),
                      backgroundColor: Color(0xFFB5EAD7),
                    ),
                  );
                },
                child: Text('Clear All Data', style: TextStyle(color: Color(0xFF6A5ACD))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFD1DC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  final TaskManager taskManager;

  AddTaskScreen({required this.taskManager});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.now();
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _reminderDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFFD1DC),
              onPrimary: Color(0xFF6A5ACD),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _reminderDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDueTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDueTime ? _dueTime : _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFFD1DC),
              onPrimary: Color(0xFF6A5ACD),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDueTime) {
          _dueTime = picked;
        } else {
          _reminderTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  labelStyle: TextStyle(color: Color(0xFF6A5ACD)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFAEC6CF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A5ACD)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Color(0xFF6A5ACD)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFAEC6CF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A5ACD)),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Due Date',
                        style: TextStyle(color: Color(0xFF6A5ACD)),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(_dueDate),
                        style: TextStyle(color: Color(0xFF6A5ACD)),
                      ),
                      trailing: Icon(Icons.calendar_today, color: Color(0xFF6A5ACD)),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Due Time',
                        style: TextStyle(color: Color(0xFF6A5ACD)),
                      ),
                      subtitle: Text(
                        _dueTime.format(context),
                        style: TextStyle(color: Color(0xFF6A5ACD)),
                      ),
                      trailing: Icon(Icons.access_time, color: Color(0xFF6A5ACD)),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Set Reminder (Optional)',
                  style: TextStyle(color: Color(0xFF6A5ACD)),
                ),
                trailing: Icon(Icons.notifications, color: Color(0xFF6A5ACD)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Set Reminder', style: TextStyle(color: Color(0xFF6A5ACD))),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text('Date', style: TextStyle(color: Color(0xFF6A5ACD))),
                              subtitle: Text(
                                _reminderDate != null
                                    ? DateFormat('MMM d, yyyy').format(_reminderDate!)
                                    : 'Select date',
                                style: TextStyle(color: Color(0xFF6A5ACD)),
                              ),
                              trailing: Icon(Icons.calendar_today, color: Color(0xFF6A5ACD)),
                              onTap: () => _selectDate(context, false),
                            ),
                            ListTile(
                              title: Text('Time', style: TextStyle(color: Color(0xFF6A5ACD))),
                              subtitle: Text(
                                _reminderTime != null
                                    ? _reminderTime!.format(context)
                                    : 'Select time',
                                style: TextStyle(color: Color(0xFF6A5ACD)),
                              ),
                              trailing: Icon(Icons.access_time, color: Color(0xFF6A5ACD)),
                              onTap: () => _selectTime(context, false),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel', style: TextStyle(color: Color(0xFF6A5ACD))),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Set', style: TextStyle(color: Color(0xFF6A5ACD))),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final dueDateTime = DateTime(
                      _dueDate.year,
                      _dueDate.month,
                      _dueDate.day,
                      _dueTime.hour,
                      _dueTime.minute,
                    );

                    DateTime? reminderDateTime;
                    if (_reminderDate != null && _reminderTime != null) {
                      reminderDateTime = DateTime(
                        _reminderDate!.year,
                        _reminderDate!.month,
                        _reminderDate!.day,
                        _reminderTime!.hour,
                        _reminderTime!.minute,
                      );
                    }

                    final newTask = Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text,
                      description: _descriptionController.text,
                      dueDate: dueDateTime,
                      reminderTime: reminderDateTime,
                    );

                    await widget.taskManager.addTask(newTask);
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Save Task',
                  style: TextStyle(fontSize: 18, color: Color(0xFF6A5ACD)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB5EAD7),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}