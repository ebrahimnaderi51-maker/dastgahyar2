import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const DastgahYarApp());
}

class DastgahYarApp extends StatelessWidget {
  const DastgahYarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دستگاه‌یار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Project {
  String id;
  String name;
  String client;
  double partsCost;
  double laborCost;
  double profitPercent;

  Project({
    required this.id,
    required this.name,
    required this.client,
    required this.partsCost,
    required this.laborCost,
    required this.profitPercent,
  });

  double get totalCost => partsCost + laborCost;
  double get profit => totalCost * profitPercent / 100;
  double get finalPrice => totalCost + profit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'client': client,
        'partsCost': partsCost,
        'laborCost': laborCost,
        'profitPercent': profitPercent,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        client: json['client'],
        partsCost: json['partsCost'].toDouble(),
        laborCost: json['laborCost'].toDouble(),
        profitPercent: json['profitPercent'].toDouble(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('projects');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        projects = jsonList.map((e) => Project.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = projects.map((e) => e.toJson()).toList();
    await prefs.setString('projects', jsonEncode(jsonList));
  }

  void addProject(Project project) {
    setState(() {
      projects.add(project);
    });
    saveProjects();
  }

  void deleteProject(int index) {
    setState(() {
      projects.removeAt(index);
    });
    saveProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دستگاه‌یار'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(
                  child: Text(
                    'هنوز پروژه‌ای ثبت نشده',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(project.name),
                        subtitle: Text(
                          '${project.client} - ${project.finalPrice.toStringAsFixed(0)} تومان',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteProject(index),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailPage(
                                project: project,
                                onDelete: () {
                                  deleteProject(index);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProjectPage(onAdd: addProject),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddProjectPage extends StatefulWidget {
  final Function(Project) onAdd;

  const AddProjectPage({super.key, required this.onAdd});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _partsController = TextEditingController();
  final _laborController = TextEditingController();
  double _profitPercent = 20;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _partsController.dispose();
    _laborController.dispose();
    super.dispose();
  }

  void saveProject() {
    if (_formKey.currentState!.validate()) {
      final project = Project(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        client: _clientController.text,
        partsCost: double.parse(_partsController.text),
        laborCost: double.parse(_laborController.text),
        profitPercent: _profitPercent,
      );
      widget.onAdd(project);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروژه جدید'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'نام دستگاه'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'لطفاً نام دستگاه را وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'نام مشتری'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partsController,
              decoration: const InputDecoration(labelText: 'هزینه قطعات (تومان)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'لطفاً هزینه قطعات را وارد کنید';
                }
                if (double.tryParse(value) == null) {
                  return 'لطفاً عدد معتبر وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _laborController,
              decoration: const InputDecoration(labelText: 'هزینه اجرت (تومان)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'لطفاً هزینه اجرت را وارد کنید';
                }
                if (double.tryParse(value) == null) {
                  return 'لطفاً عدد معتبر وارد کنید';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('درصد سود: ${_profitPercent.toStringAsFixed(0)}٪'),
            Slider(
              value: _profitPercent,
              min: 0,
              max: 50,
              divisions: 50,
              label: _profitPercent.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _profitPercent = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveProject,
              child: const Text('ذخیره پروژه'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectDetailPage extends StatelessWidget {
  final Project project;
  final VoidCallback onDelete;

  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.onDelete,
  });

  void shareProject() {
    final text = '''
دستگاه‌یار - برآورد قیمت

نام دستگاه: ${project.name}
مشتری: ${project.client}

هزینه قطعات: ${project.partsCost.toStringAsFixed(0)} تومان
هزینه اجرت: ${project.laborCost.toStringAsFixed(0)} تومان
جمع هزینه: ${project.totalCost.toStringAsFixed(0)} تومان
سود (${project.profitPercent.toStringAsFixed(0)}٪): ${project.profit.toStringAsFixed(0)} تومان
قیمت نهایی: ${project.finalPrice.toStringAsFixed(0)} تومان
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: shareProject,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مشتری: ${project.client}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRow('هزینه قطعات', project.partsCost, Colors.blue),
                  _buildRow('هزینه اجرت', project.laborCost, Colors.green),
                  const Divider(),
                  _buildRow('جمع هزینه', project.totalCost, Colors.orange),
                  _buildRow('سود', project.profit, Colors.purple),
                  const Divider(),
                  _buildRow('قیمت نهایی', project.finalPrice, Colors.red,
                      bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('حذف پروژه'),
                  content: const Text('آیا مطمئن هستید؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete();
                      },
                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete),
            label: const Text('حذف پروژه'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} تومان',
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
