import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/hike_records.dart';
import '../data/mock_data.dart';

/// Every Firebase call in the app goes through here, so screens never talk
/// to Firestore directly and the data layer can change in one place.
class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static String? get uid => _auth.currentUser?.uid;
  static bool get isSignedIn => _auth.currentUser != null;

  static DocumentReference<Map<String, dynamic>> _userDoc(String id) =>
      _db.collection('users').doc(id);

  static Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
    required String emergencyContactName,
    required String emergencyContactNumber,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // The password never touches Firestore. Firebase Auth holds it.
      await _userDoc(cred.user!.uid).set({
        'fullName': fullName,
        'email': email.toLowerCase(),
        'experienceLevel': 'Intermediate Hiker',
        'emergencyContactName': emergencyContactName,
        'emergencyContactNumber': emergencyContactNumber,
        'photoUrl': null,
        'currentGroupCode': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      HikerProfile.fullName = fullName;
      HikerProfile.email = email.toLowerCase();
      HikerProfile.emergencyContact = emergencyContactName;
      HikerProfile.emergencyNumber = emergencyContactNumber;
      HikeLog.records.clear();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } on FirebaseException catch (e) {
      return 'Account created, but the profile could not be saved (${e.code}).';
    } catch (_) {
      return 'Something went wrong. Check your connection and try again.';
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadProfile(cred.user!.uid);
      await loadHikes();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Something went wrong. Check your connection and try again.';
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    HikerProfile.signOut();
    HikeLog.records.clear();
    ActiveHike.clear();
    GroupSession.current = null;
  }

  /// Emails a reset link. Free plan, no server required.
  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether the email has an account.
      if (e.code == 'user-not-found') return null;
      return _authMessage(e);
    } catch (_) {
      return 'No connection. Check your internet and try again.';
    }
  }

  /// Checks the code taken from the reset link. Returns the account email.
  static Future<String> verifyResetCode(String code) async {
    try {
      return await _auth.verifyPasswordResetCode(code);
    } on FirebaseAuthException catch (e) {
      throw _authMessage(e);
    } catch (_) {
      throw 'No connection. Check your internet and try again.';
    }
  }

  /// Sets the new password using the code from the reset link.
  static Future<String?> confirmReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'No connection. Check your internet and try again.';
    }
  }

  static String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email. Try logging in.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'That password is too weak. Follow the rules above.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'That email and password do not match an account.';
      case 'expired-action-code':
        return 'This reset link has expired. Request a new one.';
      case 'invalid-action-code':
        return 'This link is invalid or was already used. Request a new one.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled in the Firebase console.';
      default:
        return 'Could not complete that request (${e.code}).';
    }
  }

  static Future<void> _loadProfile(String id) async {
    final snap = await _userDoc(id).get();
    final data = snap.data();
    if (data == null) return;

    HikerProfile.fullName = data['fullName'] as String? ?? '';
    HikerProfile.email = data['email'] as String? ?? '';
    HikerProfile.experienceLevel =
        data['experienceLevel'] as String? ?? 'Intermediate Hiker';
    HikerProfile.emergencyContact =
        data['emergencyContactName'] as String? ?? '';
    HikerProfile.emergencyNumber =
        data['emergencyContactNumber'] as String? ?? '';
  }

  static Future<void> saveProfile() async {
    final id = uid;
    if (id == null) return;

    await _userDoc(id).update({
      'fullName': HikerProfile.fullName,
      'experienceLevel': HikerProfile.experienceLevel,
      'emergencyContactName': HikerProfile.emergencyContact,
      'emergencyContactNumber': HikerProfile.emergencyNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static CollectionReference<Map<String, dynamic>> _hikes(String id) =>
      _userDoc(id).collection('hikes');

  static Future<void> saveHike(HikeRecord record) async {
    final id = uid;
    if (id == null) return;

    await _hikes(id).add({
      'mountainName': record.mountainName,
      'region': record.region,
      'difficulty': record.difficulty,
      'distanceKm': record.distanceKm,
      'movingTimeSeconds': record.movingTime.inSeconds,
      'completedAt': Timestamp.fromDate(record.completedAt),
    });
  }

  static Future<void> loadHikes() async {
    final id = uid;
    if (id == null) return;

    final snap =
        await _hikes(id).orderBy('completedAt', descending: true).get();

    HikeLog.records
      ..clear()
      ..addAll(snap.docs.map((doc) {
        final d = doc.data();
        return HikeRecord(
          mountainName: d['mountainName'] as String? ?? 'Unknown',
          region: d['region'] as String? ?? '',
          difficulty: d['difficulty'] as String? ?? 'Intermediate',
          distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0,
          movingTime: Duration(
              seconds: (d['movingTimeSeconds'] as num?)?.toInt() ?? 0),
          completedAt:
              (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }));
  }
}
