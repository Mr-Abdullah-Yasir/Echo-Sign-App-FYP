# EchoSign Phase 1 — Offline Accounts and Database

This patch adds:

- Local SQLite database
- `users`, `translations`, `favorites`, and `sign_videos` tables
- Offline email/password signup and login
- Salted, repeated SHA-256 password hashing
- Local login session
- Dynamic profile data and translation count
- Functional logout
- Removed phone and avatar fields from signup

## Copy these files

Copy the folders/files in this patch into the matching locations of your Flutter project:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/models/app_user.dart`
- `lib/services/database_service.dart`
- `lib/services/password_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/signup_screen.dart`
- `lib/screens/profile.dart`

Keep your other screen files unchanged.

Then run:

```bash
flutter clean
flutter pub get
flutter run
```

## Test

1. Create an account with name, email, and password.
2. Close and reopen the app; the session is stored locally.
3. Sign out from Profile.
4. Sign in again with the same email/password.
5. Try creating the same email twice; it should be rejected.

## Important

The backup button is intentionally a placeholder. Backup/restore is the next phase.

The password handling is suitable for this offline student prototype but should be upgraded to a dedicated password KDF such as PBKDF2/Argon2 before treating the app as security-critical.
