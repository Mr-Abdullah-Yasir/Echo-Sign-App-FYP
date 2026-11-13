import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database_service.dart';

class CloudBackupService {
  CloudBackupService._();

  static final CloudBackupService instance = CloudBackupService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _backupRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('backups')
        .doc('latest');
  }

  Future<DateTime?> getLastBackupTime() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _backupRef(user.uid).get();
    final value = snapshot.data()?['backedUpAt'];

    if (value is Timestamp) return value.toDate();
    return null;
  }

  Future<int> createCloudBackup({required int localUserId}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Sign in before creating a cloud backup.');
    }

    final backup = await DatabaseService.instance.exportUserBackup(localUserId);
    final rawTranslations = backup['translations'];

    if (rawTranslations is! List) {
      throw const FormatException('Local backup data is invalid.');
    }

    final backupRef = _backupRef(firebaseUser.uid);
    final translationsRef = backupRef.collection('translations');

    // Remove the previous cloud snapshot in chunks.
    while (true) {
      final old = await translationsRef.limit(400).get();
      if (old.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in old.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (old.docs.length < 400) break;
    }

    await backupRef.set(
      <String, dynamic>{
        'format': 'echosign_cloud_backup',
        'version': 1,
        'backedUpAt': FieldValue.serverTimestamp(),
        'itemCount': rawTranslations.length,
        'profile': backup['profile'],
      },
      SetOptions(merge: false),
    );

    // Firestore batches are intentionally kept below the maximum write count.
    for (var start = 0; start < rawTranslations.length; start += 400) {
      final end = (start + 400 < rawTranslations.length)
          ? start + 400
          : rawTranslations.length;

      final batch = _firestore.batch();

      for (var index = start; index < end; index++) {
        final raw = rawTranslations[index];
        if (raw is! Map) continue;

        final docId = 'item_${index.toString().padLeft(6, '0')}';
        batch.set(
          translationsRef.doc(docId),
          <String, dynamic>{
            'order': index,
            'english_text': raw['english_text'],
            'asl_gloss': raw['asl_gloss'],
            'created_at': raw['created_at'],
            'is_favorite': raw['is_favorite'] == true,
          },
        );
      }

      await batch.commit();
    }

    return rawTranslations.length;
  }

  Future<int> restoreCloudBackup({required int localUserId}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Sign in before restoring a cloud backup.');
    }

    final backupRef = _backupRef(firebaseUser.uid);
    final metadata = await backupRef.get();

    if (!metadata.exists) {
      throw StateError('No Firebase backup exists for this account yet.');
    }

    final meta = metadata.data();
    if (meta?['format'] != 'echosign_cloud_backup' || meta?['version'] != 1) {
      throw const FormatException('The Firebase backup format is not supported.');
    }

    final translationsSnapshot = await backupRef
        .collection('translations')
        .orderBy('order')
        .get();

    final translations = translationsSnapshot.docs
        .map(
          (doc) => <String, dynamic>{
            'english_text': doc.data()['english_text'] ?? '',
            'asl_gloss': doc.data()['asl_gloss'] ?? '',
            'created_at': doc.data()['created_at'] ?? DateTime.now().toIso8601String(),
            'is_favorite': doc.data()['is_favorite'] == true,
          },
        )
        .toList();

    final backup = <String, dynamic>{
      'format': 'echosign_backup',
      'version': 1,
      'profile': meta?['profile'] ??
          <String, dynamic>{
            'full_name': 'EchoSign User',
            'email': firebaseUser.email ?? '',
          },
      'translations': translations,
    };

    await DatabaseService.instance.restoreUserBackup(
      userId: localUserId,
      backup: backup,
    );

    return translations.length;
  }
}
