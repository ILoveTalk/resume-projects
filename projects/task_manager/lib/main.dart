import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFF1F2937),
        hintColor: const Color(0xFF10B981),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF9FAFB)),
          bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF4F46E5),
        ),
      ),
      home: const TaskManagerPage(),
    );
  }
}

class Task {
  final String id;
  final String title;
  bool completed;

  Task({required this.id, required this.title, this.completed = false});

  // Convert a Task into a Map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };

  // Create a Task from a Map.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

class TaskManagerPage extends StatefulWidget {
  const TaskManagerPage({super.key});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  List<Task> _tasks = [];
  String _currentFilter = 'all';
  late final AnimationController _animationController;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> taskList = jsonDecode(tasksString);
      setState(() {
        _tasks = taskList.map((item) => Task.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksString);
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) return;
    setState(() {
      _tasks.insert(0, Task(id: DateTime.now().toString(), title: _taskController.text.trim()));
      _taskController.clear();
      _saveTasks();
    });
  }

  void _toggleTask(String taskId) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex].completed = !_tasks[taskIndex].completed;
        _saveTasks();
      }
    });
  }

  void _deleteTask(String taskId) {
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
      _saveTasks();
    });
  }

  void _clearCompleted() {
    setState(() {
      _tasks.removeWhere((task) => task.completed);
      _saveTasks();
    });
  }

  List<Task> get _filteredTasks {
    if (_currentFilter == 'active') {
      return _tasks.where((task) => !task.completed).toList();
    } else if (_currentFilter == 'completed') {
      return _tasks.where((task) => task.completed).toList();
    }
    return _tasks;
  }

  int get _activeTaskCount => _tasks.where((task) => !task.completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32.0),
              _buildTaskListContainer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 12),
            Text(
              'Task Manager',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.05,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskListContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildAddTaskForm(),
            _buildTaskList(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTaskForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4B5563), width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: 'Create a new task...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
              ),
              onSubmitted: (value) => _addTask(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_filteredTasks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'All clear!',
                style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFD1D5DB)),
              ),
              SizedBox(height: 4),
              Text(
                'Looks like there are no tasks here.',
                style: TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            background: Container(
              color: const Color(0xFFEF4444),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_forever, color: Colors.white),
            ),
            child: _buildTaskItem(task),
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF4B5563))),
      ),
      child: ListTile(
        onTap: () => _toggleTask(task.id),
        leading: GestureDetector(
          onTap: () => _toggleTask(task.id),
          child: AnimatedContainer(
            duration: _animationDuration,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.completed
                  ? const Color(0xFF4F46E5)
                  : Colors.transparent,
              border: Border.all(
                color: task.completed ? const Color(0xFF4F46E5) : const Color(0xFF4B5563),
                width: 2,
              ),
              gradient: task.completed
                  ? const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
              )
                  : null,
            ),
            child: task.completed
                ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 18,
            color: task.completed ? const Color(0xFFD1D5DB) : const Color(0xFFF9FAFB),
            decoration: task.completed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFD1D5DB)),
          onPressed: () => _deleteTask(task.id),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF4B5563))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              children: [
                _buildFilterButtons(),
                const SizedBox(height: 16),
                _buildClearCompletedButton(),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_activeTaskCount items left',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB))),
                _buildFilterButtons(),
                _buildClearCompletedButton(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Wrap(
      spacing: 16,
      children: [
        _buildFilterButton('all', 'All'),
        _buildFilterButton('active', 'Active'),
        _buildFilterButton('completed', 'Completed'),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final bool isActive = _currentFilter == filter;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Theme.of(context).primaryColor : const Color(0xFFD1D5DB),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildClearCompletedButton() {
    return TextButton(
      onPressed: _clearCompleted,
      child: const Text(
        'Clear Completed',
        style: TextStyle(
          color: Color(0xFFD1D5DB),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}