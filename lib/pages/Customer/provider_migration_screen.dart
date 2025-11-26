import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderMigrationScreen extends StatefulWidget {
  const ProviderMigrationScreen({super.key});

  @override
  State<ProviderMigrationScreen> createState() => _ProviderMigrationScreenState();
}

class _ProviderMigrationScreenState extends State<ProviderMigrationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isMigrating = false;
  String _status = 'Press the button to migrate provider data';

  Future<void> _migrateProviders() async {
    setState(() {
      _isMigrating = true;
      _status = 'Migrating...';
    });

    try {
      final providers = await _db.collection('providers').get();

      for (var doc in providers.docs) {
        final data = doc.data();
        final userId = data['userId'];

        final userDoc = await _db.collection('users').doc(userId).get();
        final name = userDoc.data()?['name'] ?? 'Unknown';

        await doc.reference.update({
          'name': name,
          'bookingCount': data['bookingCount'] ?? 0,
          'location': data['location'] ?? const GeoPoint(0.0, 0.0),
        });
      }

      setState(() {
        _status = '✅ Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Migrate Provider Data"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isMigrating ? null : _migrateProviders,
              icon: const Icon(Icons.update),
              label: const Text("Run Migration"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
