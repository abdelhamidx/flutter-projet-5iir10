import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(String task, DateTime deadline) async {
    await tasksCollection.add({
      'task': task,
      'deadline': deadline,
    });
  }

  Future<void> updateTask(String docID, String task, DateTime deadline) async {
    await tasksCollection.doc(docID).update({
      'task': task,
      'deadline': deadline,
    });
  }

  Future<void> deleteTask(String docID) async {
    await tasksCollection.doc(docID).delete();
  }

  Stream<QuerySnapshot> getTasksStream() {
    return tasksCollection.orderBy('deadline', descending: false).snapshots();
  }
}
