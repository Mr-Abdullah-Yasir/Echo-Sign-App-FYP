import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileImageService {
  ProfileImageService._();

  static final ProfileImageService instance = ProfileImageService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxImageBytes = 550 * 1024;

  Future<Uint8List?> pickImageBytes() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose profile picture',
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw StateError('Could not read the selected image.');
    }

    if (bytes.length > maxImageBytes) {
      throw StateError(
        'Please choose an image smaller than 550 KB. A cropped or screenshot image works best.',
      );
    }

    return bytes;
  }

  Future<void> saveProfileImage(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');

    if (bytes.length > maxImageBytes) {
      throw StateError('Profile image is too large.');
    }

    await _firestore.collection('users').doc(user.uid).set(
      <String, dynamic>{
        'profileImageBase64': base64Encode(bytes),
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Uint8List?> loadProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final encoded = snapshot.data()?['profileImageBase64'];

    if (encoded is! String || encoded.isEmpty) return null;

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update(
      <String, dynamic>{
        'profileImageBase64': FieldValue.delete(),
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
