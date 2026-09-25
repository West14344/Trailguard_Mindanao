import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    required String emergencyContactEmail,
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
      HikerProfile.emergencyEmail = emergencyContactEmail;
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
    GroupSession.clear();
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

  // -------------------------------------------------------------------------
  // Hazards
  // -------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> get _hazards =>
      _db.collection("hazards");

  /// Posts a hazard so every other hiker sees it. Location comes from the
  /// device, so the report is pinned to where it was actually filed.
  static Future<String?> reportHazard({
    required String type,
    required String description,
    required String nearestTrail,
    double? latitude,
    double? longitude,
  }) async {
    final id = uid;
    if (id == null) return "You need to be logged in to report a hazard.";

    try {
      await _hazards.add({
        "type": type,
        "description": description,
        "nearestTrail": nearestTrail,
        "latitude": latitude,
        "longitude": longitude,
        "reportedBy": id,
        "reportedByName": HikerProfile.fullName,
        "reportedAt": FieldValue.serverTimestamp(),
        "status": "active",
      });
      return null;
    } on FirebaseException catch (e) {
      return "Could not send the report (${e.code}). Try again.";
    } catch (_) {
      return "No connection. Your report was not sent.";
    }
  }

  /// Live feed of active hazards, newest first. Returns a stream so the
  /// Alerts tab updates the moment somebody files a report.
  static Stream<List<TrailAlert>> hazardStream() {
    return _hazards
        .where("status", isEqualTo: "active")
        .orderBy("reportedAt", descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_alertFromDoc).toList());
  }

  static TrailAlert _alertFromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final type = d["type"] as String? ?? "Hazard";
    final trail = d["nearestTrail"] as String? ?? "Unknown trail";
    final reportedAt = (d["reportedAt"] as Timestamp?)?.toDate();

    return TrailAlert(
      title: type,
      detail: "$trail - ${_ago(reportedAt)}",
      level: _levelFor(type),
      icon: _iconFor(type),
    );
  }

  /// Wildfire and landslide can kill; a missing sign is an inconvenience.
  static AlertLevel _levelFor(String type) {
    switch (type) {
      case "Wildfire":
      case "Landslide":
      case "Flooded trail":
        return AlertLevel.critical;
      case "Damaged bridge":
      case "Blocked path":
      case "Wildlife":
        return AlertLevel.caution;
      default:
        return AlertLevel.notice;
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case "Fallen tree":
        return Icons.park_outlined;
      case "Flooded trail":
        return Icons.water_outlined;
      case "Wildfire":
        return Icons.local_fire_department_outlined;
      case "Landslide":
        return Icons.landslide_outlined;
      case "Blocked path":
        return Icons.block_outlined;
      case "Damaged bridge":
        return Icons.dangerous_outlined;
      case "Wildlife":
        return Icons.pets_outlined;
      case "Missing trail sign":
        return Icons.signpost_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  static String _ago(DateTime? time) {
    if (time == null) return "just now";
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) {
      return "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
    }
    return "${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago";
  }

  // -------------------------------------------------------------------------
  // Groups
  // -------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection("groups");

  static DocumentReference<Map<String, dynamic>> _groupDoc(String code) =>
      _groups.doc(code.toUpperCase());

  static CollectionReference<Map<String, dynamic>> _members(String code) =>
      _groupDoc(code).collection("members");

  static Future<bool> groupExists(String code) async {
    final snap = await _groupDoc(code).get();
    return snap.exists;
  }

  /// Creates the group and adds the current hiker as its first member.
  /// Returns null on success, or a message to show.
  static Future<String?> createGroup({
    required String name,
    required String code,
  }) async {
    final id = uid;
    if (id == null) return "You need to be logged in to create a group.";

    try {
      final upper = code.toUpperCase();
      if (await groupExists(upper)) {
        return "That code is already taken. Generate another.";
      }

      await _groupDoc(upper).set({
        "name": name,
        "code": upper,
        "createdBy": id,
        "createdAt": FieldValue.serverTimestamp(),
        "active": true,
      });

      await _joinAsMember(upper);
      return null;
    } on FirebaseException catch (e) {
      return "Could not create the group (${e.code}).";
    } catch (_) {
      return "No connection. Check your internet and try again.";
    }
  }

  /// Joins an existing group by code. Works across devices, since the
  /// group lives in Firestore rather than on one phone.
  static Future<String?> joinGroup(String code) async {
    final id = uid;
    if (id == null) return "You need to be logged in to join a group.";

    try {
      final snap = await _groupDoc(code).get();
      if (!snap.exists) {
        return "No group found with that code. Check it with whoever "
            "created it.";
      }

      await _joinAsMember(code.toUpperCase());
      return null;
    } on FirebaseException catch (e) {
      return "Could not join the group (${e.code}).";
    } catch (_) {
      return "No connection. Check your internet and try again.";
    }
  }

  static Future<void> _joinAsMember(String code) async {
    final id = uid;
    if (id == null) return;

    await _members(code).doc(id).set({
      "name": HikerProfile.fullName,
      "email": HikerProfile.email,
      "latitude": null,
      "longitude": null,
      "lastUpdated": FieldValue.serverTimestamp(),
      "joinedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _userDoc(id).update({"currentGroupCode": code});
  }

  /// The group's name, or null if it has gone.
  static Future<String?> groupName(String code) async {
    final snap = await _groupDoc(code).get();
    return snap.data()?["name"] as String?;
  }

  /// Pushes this hiker's position so everyone else sees them move.
  /// Called from the group screen while a hike is running.
  static Future<void> updateMyPosition({
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    final id = uid;
    if (id == null) return;

    try {
      await _members(code).doc(id).update({
        "latitude": latitude,
        "longitude": longitude,
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // A dropped position update is not worth interrupting the hike for.
    }
  }

  /// Live list of everyone in the group, updating as they move.
  static Stream<List<GroupMember>> memberStream(String code) {
    return _members(code).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final d = doc.data();
        return GroupMember(
          name: d["name"] as String? ?? "Hiker",
          email: d["email"] as String? ?? "",
          latitude: (d["latitude"] as num?)?.toDouble(),
          longitude: (d["longitude"] as num?)?.toDouble(),
          lastUpdated: (d["lastUpdated"] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  /// Removes this hiker. The group is deleted when the last person leaves.
  static Future<void> leaveGroup(String code) async {
    final id = uid;
    if (id == null) return;

    try {
      await _members(code).doc(id).delete();
      await _userDoc(id).update({"currentGroupCode": null});

      final remaining = await _members(code).limit(1).get();
      if (remaining.docs.isEmpty) {
        await _groupDoc(code).delete();
      }
    } catch (_) {
      // Leaving locally matters more than the cleanup succeeding.
    }
  }

  /// The group this hiker was in when they last used the app, so a
  /// restart does not drop them out of it.
  static Future<String?> savedGroupCode() async {
    final id = uid;
    if (id == null) return null;
    final snap = await _userDoc(id).get();
    return snap.data()?["currentGroupCode"] as String?;
  }

  // -------------------------------------------------------------------------
  // Emergency SOS
  // -------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> get _sosEvents =>
      _db.collection("sosEvents");

  /// Records the emergency so rangers and the hiker's contact have
  /// something to act on. Returns the document id, or null if it failed.
  static Future<String?> recordSos({
    double? latitude,
    double? longitude,
    double? accuracyM,
    String? trailName,
  }) async {
    final id = uid;
    if (id == null) return null;

    try {
      final doc = await _sosEvents.add({
        "userId": id,
        "userName": HikerProfile.fullName,
        "userEmail": HikerProfile.email,
        "latitude": latitude,
        "longitude": longitude,
        "accuracyM": accuracyM,
        "trailName": trailName ?? "Unknown",
        "emergencyContactName": HikerProfile.emergencyContact,
        "emergencyContactNumber": HikerProfile.emergencyNumber,
      "emergencyContactEmail": HikerProfile.emergencyEmail,
        "groupCode": GroupSession.code,
        "triggeredAt": FieldValue.serverTimestamp(),
        "resolved": false,
      });
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  /// Marks the emergency over, so an old SOS does not sit open forever.
  static Future<void> resolveSos(String eventId) async {
    try {
      await _sosEvents.doc(eventId).update({
        "resolved": true,
        "resolvedAt": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Nothing useful to tell the hiker if this fails.
    }
  }

  /// Keeps the position current while an SOS is open, so rescuers see
  /// where the hiker moved to rather than where they started.
  static Future<void> updateSosPosition({
    required String eventId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _sosEvents.doc(eventId).update({
        "latitude": latitude,
        "longitude": longitude,
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // A dropped update is not worth surfacing mid-emergency.
    }
  }

  /// Hazards with coordinates, for plotting on the trail map.
  static Stream<List<HazardReport>> hazardReportStream() {
    return _hazards
        .where("status", isEqualTo: "active")
        .orderBy("reportedAt", descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return HazardReport(
                id: doc.id,
                type: d["type"] as String? ?? "Hazard",
                description: d["description"] as String? ?? "",
                nearestTrail: d["nearestTrail"] as String? ?? "Unknown trail",
                latitude: (d["latitude"] as num?)?.toDouble(),
                longitude: (d["longitude"] as num?)?.toDouble(),
                reportedByName: d["reportedByName"] as String? ?? "A hiker",
                reportedAt: (d["reportedAt"] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  // -------------------------------------------------------------------------
  // Group chat
  // -------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> _messages(String code) =>
      _groupDoc(code).collection("messages");

  static Future<void> sendMessage({
    required String code,
    required String text,
  }) async {
    final id = uid;
    if (id == null || text.trim().isEmpty) return;

    await _messages(code).add({
      "text": text.trim(),
      "senderId": id,
      "senderName": HikerProfile.fullName,
      "sentAt": FieldValue.serverTimestamp(),
    });
  }

  /// Newest last, so the list reads top to bottom like a conversation.
  static Stream<List<GroupMessage>> messageStream(String code) {
    return _messages(code)
        .orderBy("sentAt", descending: true)
        .limit(100)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return GroupMessage(
          id: doc.id,
          text: d["text"] as String? ?? "",
          senderId: d["senderId"] as String? ?? "",
          senderName: d["senderName"] as String? ?? "Hiker",
          sentAt: (d["sentAt"] as Timestamp?)?.toDate(),
        );
      }).toList();
      return list.reversed.toList();
    });
  }

  /// Keeps the name shown to the group in step with profile edits.
  static Future<void> syncNameToGroup() async {
    final id = uid;
    final code = GroupSession.code;
    if (id == null || code == null) return;

    try {
      await _members(code).doc(id).update({"name": HikerProfile.fullName});
    } catch (_) {
      // Not worth interrupting a profile save for.
    }
  }

  // -------------------------------------------------------------------------
  // Language
  // -------------------------------------------------------------------------

  static Future<void> saveLanguage(String code) async {
    final id = uid;
    if (id == null) return;
    try {
      await _userDoc(id).update({"language": code});
    } catch (_) {
      // The choice still applies locally if this fails.
    }
  }

  static Future<String?> savedLanguage() async {
    final id = uid;
    if (id == null) return null;
    final snap = await _userDoc(id).get();
    return snap.data()?["language"] as String?;
  }

  // -------------------------------------------------------------------------
  // Account deletion
  // -------------------------------------------------------------------------

  /// Firebase refuses to delete an account unless the user signed in
  /// recently, so the password is re-checked first.
  static Future<String?> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final id = user?.uid;
    if (user == null || id == null) return "You are not signed in.";

    try {
      // Prove it is really them before destroying anything.
      final credential = EmailAuthProvider.credential(
        email: user.email ?? HikerProfile.email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-credential" || e.code == "wrong-password") {
        return "That password is incorrect.";
      }
      return _authMessage(e);
    }

    try {
      // Leave any group first, so the others stop seeing a ghost member.
      final code = GroupSession.code ?? await savedGroupCode();
      if (code != null) await leaveGroup(code);

      // Hike history lives in a subcollection, which must be cleared
      // before the parent document.
      final hikes = await _hikes(id).get();
      for (final doc in hikes.docs) {
        await doc.reference.delete();
      }

      await _userDoc(id).delete();
      await user.delete();

      HikerProfile.signOut();
      HikeLog.records.clear();
      ActiveHike.clear();
      GroupSession.clear();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return "Could not finish deleting the account. Try again.";
    }
  }

  static Future<void> saveTheme(String code) async {
    final id = uid;
    if (id == null) return;
    try {
      await _userDoc(id).update({"theme": code});
    } catch (_) {
      // The choice still applies locally if this fails.
    }
  }
}














