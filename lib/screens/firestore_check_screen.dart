// TEST_firestore_check.dart
// Run this as a widget to test Firestore connection

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreCheckScreen extends StatefulWidget {
  const FirestoreCheckScreen({super.key});

  @override
  State<FirestoreCheckScreen> createState() => _FirestoreCheckScreenState();
}

class _FirestoreCheckScreenState extends State<FirestoreCheckScreen> {
  List<String> logs = [];
  bool isChecking = false;

  void addLog(String message) {
    setState(() {
      logs.add(message);
    });
    print(message);
  }

  Future<void> runCheck() async {
    setState(() {
      logs.clear();
      isChecking = true;
    });

    try {
      // Check 1: Firebase Auth
      addLog('✅ Step 1: Checking Firebase Auth...');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        addLog('❌ ERROR: Not logged in!');
        setState(() => isChecking = false);
        return;
      }

      addLog('✅ Logged in as: ${currentUser.email}');
      addLog('✅ User ID: ${currentUser.uid}');
      addLog('');

      // Check 2: Firestore Connection
      addLog('✅ Step 2: Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      addLog('✅ Firestore instance created');
      addLog('');

      // Check 3: Query trips for current user
      addLog('✅ Step 3: Querying trips for user...');
      addLog('Query: trips where userId == ${currentUser.uid}');

      final tripsSnapshot = await firestore
          .collection('trips')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      addLog('✅ Query completed!');
      addLog('Found ${tripsSnapshot.docs.length} trips');
      addLog('');

      // Check 4: Show trip details
      if (tripsSnapshot.docs.isEmpty) {
        addLog('❌ No trips found for this user!');
        addLog('');
        addLog('📊 Checking ALL trips in database...');

        final allTripsSnapshot = await firestore.collection('trips').get();
        addLog('Total trips in database: ${allTripsSnapshot.docs.length}');

        if (allTripsSnapshot.docs.isNotEmpty) {
          addLog('');
          addLog('❌ PROBLEM FOUND: Trips exist but with different userId!');
          addLog('');

          for (var doc in allTripsSnapshot.docs) {
            final data = doc.data();
            addLog('Trip: ${data['destination'] ?? 'Unknown'}');
            addLog('  Trip userId: ${data['userId']}');
            addLog('  Your userId: ${currentUser.uid}');
            addLog('  Match: ${data['userId'] == currentUser.uid ? '✅' : '❌'}');
            addLog('');
          }
        } else {
          addLog('✅ Database is empty - no trips created yet');
        }
      } else {
        addLog('✅ SUCCESS: Found trips for this user!');
        addLog('');

        for (var doc in tripsSnapshot.docs) {
          final data = doc.data();
          addLog('Trip: ${data['destination'] ?? 'Unknown'}');
          addLog('  ID: ${doc.id}');
          addLog('  Budget: ${data['totalBudget']}');
          addLog('  Dates: ${data['startDate']} to ${data['endDate']}');
          addLog('');
        }
      }

      // Check 5: Test write permission
      addLog('✅ Step 4: Testing write permission...');
      try {
        await firestore.collection('_test').add({
          'test': true,
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        addLog('✅ Write permission OK');

        // Clean up test document
        final testDocs = await firestore
            .collection('_test')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
        for (var doc in testDocs.docs) {
          await doc.reference.delete();
        }
        addLog('✅ Cleaned up test data');
      } catch (e) {
        addLog('❌ Write permission DENIED: $e');
      }
      addLog('');

      // Summary
      addLog('━━━━━━━━━━━━━━━━━━━━━━━━');
      addLog('SUMMARY:');
      addLog('━━━━━━━━━━━━━━━━━━━━━━━━');
      addLog('Auth: ✅ Working');
      addLog('Firestore: ✅ Connected');
      addLog('Your trips: ${tripsSnapshot.docs.length}');
      addLog(
          'Total trips: ${(await firestore.collection('trips').get()).docs.length}');
    } catch (e) {
      addLog('❌ ERROR: $e');
    }

    setState(() => isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Connection Check'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: isChecking ? null : runCheck,
                  child: isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Run Diagnostic Check'),
                ),
                if (logs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => logs.clear());
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Logs'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text('Click "Run Diagnostic Check" to start'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: log.contains('❌')
                                ? Colors.red
                                : log.contains('✅')
                                    ? Colors.green
                                    : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// To use this:
// 1. Add a button in your app to navigate here
// 2. OR temporarily replace TripsScreen with FirestoreCheckScreen
// 3. Run the check and screenshot the results
