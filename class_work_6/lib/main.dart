import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(TasksApp());
}

class TasksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  TaskListScreen({super.key, required this.title});
  final String title;
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _id = 0;

  final CollectionReference _tasks = FirebaseFirestore.instance.collection('tasks',);

  Future<void> _deleteTask(String id) async {
    await _tasks.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.blue, actions: [IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Sign Out',
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
      ),],
      ),
      body: StreamBuilder(
        stream: _tasks.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Card(
                  color: documentSnapshot['completed'] ? const Color.fromARGB(255, 103, 244, 107) : const Color.fromARGB(255, 248, 80, 68),
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Checkbox(value: documentSnapshot['completed'], onChanged: (value) {
                      _tasks.doc(documentSnapshot.id).update({
                        'completed': value,
                      });
                    }),
                    title: Text(documentSnapshot['name']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _createOrUpdate(documentSnapshot),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                () => _deleteTask(documentSnapshot.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createOrUpdate();
        },
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
    }
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    if (action == 'create') {
                      await _tasks.add(<String, dynamic>{
                        'id': _id,
                        'name': _nameController.text,
                        'completed': false,
                      });

                      _id++;
                      _nameController.text = '';

                    } else {
                      await _tasks.doc(documentSnapshot!.id).update(
                        <String, dynamic>{
                          'name': _nameController.text,
                        },
                      );

                      _nameController.text = '';
                    }
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(action == 'create' ? 'Create' : 'Update'),
              ),
            ],
          ),
        );
      },
    );
  }
}