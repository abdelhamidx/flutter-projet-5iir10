import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projet/services/filestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Future<void> openNoteBox({String? docID, String? initialNote, DateTime? initialDate}) async {
    textController.text = initialNote ?? '';
    selectedDate = initialDate ?? DateTime.now();

    DateTime? selectedDateTime = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDateTime != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        selectedDate = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          children: [
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your task',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Deadline: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour}:${selectedDate.minute}",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (docID == null) {
                await firestoreService.addTask(textController.text, selectedDate);
              } else {
                await firestoreService.updateTask(docID, textController.text, selectedDate);
              }
              textController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
            ),
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Color.fromARGB(255, 141, 152, 198),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              // Add any action you want for the info button
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List tasksList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: tasksList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = tasksList[index];
                String docID = document.id;
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String taskText = data['task'];
                Timestamp deadlineTimestamp = data['deadline'];

                DateTime deadlineDateTime = deadlineTimestamp.toDate();
                String formattedDeadlineDate =
                    "${deadlineDateTime.day}/${deadlineDateTime.month}/${deadlineDateTime.year} ${deadlineDateTime.hour}:${deadlineDateTime.minute}";

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      taskText,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To be completed Before: $formattedDeadlineDate",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => openNoteBox(docID: docID, initialNote: taskText, initialDate: deadlineDateTime),
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                        ),
                        IconButton(
                          onPressed: () => firestoreService.deleteTask(docID),
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: const Text('No tasks!'),
            );
          }
        },
      ),
    );
  }
}
