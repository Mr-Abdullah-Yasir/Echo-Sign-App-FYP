import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/database_service.dart';

enum SignUpResult {
  success,
  usernameTaken,
  emailAlreadyInUse,
  failure,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _needsEmailVerification = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get needsEmailVerification => _needsEmailVerification;
  User? get firebaseUser => _firebaseAuth.currentUser;

  Future<SignUpResult> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _needsEmailVerification = false;

    final cleanName = fullName.trim();
    final cleanUsername = username.trim();
    final usernameLower = cleanUsername.toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    UserCredential? credential;
    DocumentReference<Map<String, dynamic>>? usernameRef;

    try {
      // Firebase Auth owns the email/password identity.
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _errorMessage = 'Firebase account could not be created.';
        return SignUpResult.failure;
      }

      usernameRef = _firestore.collection('usernames').doc(usernameLower);
      final userRef = _firestore.collection('users').doc(user.uid);

      // Reserve the username and create the profile atomically.
      await _firestore.runTransaction((transaction) async {
        final existingUsername = await transaction.get(usernameRef!);
        if (existingUsername.exists) {
          throw StateError('username-taken');
        }

        transaction.set(usernameRef!, {
          'uid': user.uid,
          'email': cleanEmail,
          'username': cleanUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(userRef, {
          'fullName': cleanName,
          'username': cleanUsername,
          'usernameLowercase': usernameLower,
          'email': cleanEmail,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await user.updateDisplayName(cleanName);

      // Create only a local profile bridge for history/favorites.
      _currentUser = await DatabaseService.instance.ensureFirebaseLocalUser(
        firebaseUid: user.uid,
        username: cleanUsername,
        fullName: cleanName,
        email: cleanEmail,
      );

      await user.sendEmailVerification();
      _needsEmailVerification = true;
      notifyListeners();
      return SignUpResult.success;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        _errorMessage = 'An account with this email already exists.';
        return SignUpResult.emailAlreadyInUse;
      }
      if (error.code == 'weak-password') {
        _errorMessage = 'Choose a stronger password.';
      } else if (error.code == 'invalid-email') {
        _errorMessage = 'Enter a valid email address.';
      } else {
        _errorMessage = error.message ?? 'The account could not be created.';
      }
      return SignUpResult.failure;
    } on StateError catch (error) {
      if (error.message == 'username-taken') {
        // Remove the Firebase Auth account that was just created so the user
        // can retry with another username using the same email.
        try {
          await credential?.user?.delete();
        } catch (_) {}
        _errorMessage = 'This username is already taken.';
        return SignUpResult.usernameTaken;
      }
      _errorMessage = 'The account could not be created.';
      return SignUpResult.failure;
    } catch (_) {
      // Best-effort cleanup for a partially created Firebase account.
      try {
        await credential?.user?.delete();
      } catch (_) {}
      _errorMessage = 'The account could not be created. Check your internet connection and try again.';
      return SignUpResult.failure;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _needsEmailVerification = false;

    try {
      final cleanIdentifier = identifier.trim().toLowerCase();
      String email;

      if (cleanIdentifier.contains('@')) {
        email = cleanIdentifier;
      } else {
        final usernameDoc =
            await _firestore.collection('usernames').doc(cleanIdentifier).get();

        if (!usernameDoc.exists) {
          _errorMessage = 'No account was found for this username.';
          return false;
        }

        final data = usernameDoc.data();
        email = (data?['email'] as String? ?? '').trim().toLowerCase();

        if (email.isEmpty) {
          _errorMessage = 'This username is not linked to a valid account.';
          return false;
        }
      }

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _errorMessage = 'Sign in failed.';
        return false;
      }

      await user.reload();
      final refreshed = _firebaseAuth.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        _needsEmailVerification = true;
        _errorMessage =
            'Your email is not verified. Verify it before opening EchoSign Pro.';
        notifyListeners();
        return false;
      }

      final profileDoc =
          await _firestore.collection('users').doc(refreshed.uid).get();
      final profile = profileDoc.data();

      if (profile == null) {
        _errorMessage = 'Your Firebase profile could not be loaded.';
        return false;
      }

      _currentUser = await DatabaseService.instance.ensureFirebaseLocalUser(
        firebaseUid: refreshed.uid,
        username: (profile['username'] as String? ?? '').trim(),
        fullName: (profile['fullName'] as String? ?? refreshed.displayName ?? 'EchoSign User').trim(),
        email: (profile['email'] as String? ?? refreshed.email ?? email).trim(),
      );

      _needsEmailVerification = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          _errorMessage = 'Incorrect username/email or password.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many sign-in attempts. Please try again later.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Internet connection is required to sign in.';
          break;
        default:
          _errorMessage = error.message ?? 'Sign in failed. Please try again.';
      }
      return false;
    } catch (_) {
      _errorMessage = 'Sign in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerificationEmail() async {
    _errorMessage = null;
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _errorMessage = 'Sign in again before requesting a verification email.';
        notifyListeners();
        return false;
      }
      if (user.emailVerified) return true;
      await user.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message ?? 'Verification email could not be sent.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Verification email could not be sent.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailVerificationAndFinish() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _errorMessage = 'Your verification session expired. Please sign in.';
        return false;
      }

      await user.reload();
      final refreshed = _firebaseAuth.currentUser;

      if (refreshed == null || !refreshed.emailVerified) {
        _errorMessage = 'Email is still not verified. Open the email link first.';
        return false;
      }

      await _firestore.collection('users').doc(refreshed.uid).update({
        'emailVerified': true,
      });

      // Required EchoSign flow: after verification, return to Login instead
      // of automatically entering the dashboard.
      await _firebaseAuth.signOut();
      _currentUser = null;
      _needsEmailVerification = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Could not confirm email verification. Try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      return true;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        _errorMessage = 'Enter a valid email address.';
      } else if (error.code == 'network-request-failed') {
        _errorMessage = 'Internet connection is required.';
      } else {
        _errorMessage = error.message ?? 'Password reset email could not be sent.';
      }
      return false;
    } catch (_) {
      _errorMessage = 'Password reset email could not be sent.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) {
      _errorMessage = 'No Firebase user is signed in.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' || error.code == 'invalid-credential') {
        _errorMessage = 'Current password is incorrect.';
      } else {
        _errorMessage = error.message ?? 'Password could not be changed.';
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    final localUser = _currentUser;

    if (firebaseUser == null || localUser == null) {
      _errorMessage = 'No user is signed in.';
      notifyListeners();
      return false;
    }

    final cleanName = fullName.trim();
    final requestedEmail = email.trim().toLowerCase();
    final currentEmail = (firebaseUser.email ?? '').trim().toLowerCase();

    if (cleanName.isEmpty) {
      _errorMessage = 'Name is required.';
      notifyListeners();
      return false;
    }

    if (requestedEmail != currentEmail) {
      _errorMessage =
          'Email changes are disabled in this phase because Firebase requires a separate verified email-change flow.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      await firebaseUser.updateDisplayName(cleanName);
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fullName': cleanName,
      });

      final profile =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      final username = profile.data()?['username'] as String? ?? '';

      _currentUser = await DatabaseService.instance.ensureFirebaseLocalUser(
        firebaseUid: firebaseUser.uid,
        username: username,
        fullName: cleanName,
        email: currentEmail,
      );
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Profile could not be updated.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null || !firebaseUser.emailVerified) return;

    final profile =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    final data = profile.data();
    if (data == null) return;

    _currentUser = await DatabaseService.instance.ensureFirebaseLocalUser(
      firebaseUid: firebaseUser.uid,
      username: data['username'] as String? ?? '',
      fullName: data['fullName'] as String? ?? firebaseUser.displayName ?? 'EchoSign User',
      email: data['email'] as String? ?? firebaseUser.email ?? '',
    );
    notifyListeners();
  }

  // Quick Login does not store the EchoSign/Firebase password.
  // Android verifies the device owner first in LoginScreen. This method then
  // reuses Firebase's persisted authenticated session and confirms that it
  // belongs to the UID that the user explicitly enabled for Quick Login.
  Future<bool> quickSignIn(String firebaseUid) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        _errorMessage =
            'Quick Login needs one normal Firebase sign-in after a full logout.';
        return false;
      }

      await firebaseUser.reload();
      final refreshed = _firebaseAuth.currentUser;

      if (refreshed == null ||
          refreshed.uid != firebaseUid ||
          !refreshed.emailVerified) {
        _errorMessage =
            'Quick Login is not available for this Firebase account.';
        return false;
      }

      final profileDoc =
          await _firestore.collection('users').doc(refreshed.uid).get();
      final profile = profileDoc.data();

      if (profile == null) {
        _errorMessage = 'Your Firebase profile could not be loaded.';
        return false;
      }

      _currentUser = await DatabaseService.instance.ensureFirebaseLocalUser(
        firebaseUid: refreshed.uid,
        username: (profile['username'] as String? ?? '').trim(),
        fullName:
            (profile['fullName'] as String? ??
                    refreshed.displayName ??
                    'EchoSign User')
                .trim(),
        email:
            (profile['email'] as String? ??
                    refreshed.email ??
                    '')
                .trim(),
      );

      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Quick Login failed. Use normal Firebase login.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _needsEmailVerification = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
