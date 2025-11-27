import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
class FirestoreService {
  // Singleton Setup
  FirestoreService._privateConstructor() {
    _listenToAuthChanges();
  }
  static final FirestoreService instance =
      FirestoreService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _deviceId = 'hydroponic_system'; // Single device for now

 
  void _listenToAuthChanges() {
    //placeholder for now
    return;
  }
  }