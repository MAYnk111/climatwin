import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ClimatwinUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  ClimatwinUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  factory ClimatwinUser.fromFirebase(User user) {
    return ClimatwinUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  FirebaseAuth? _auth;
  final _authStateController = StreamController<ClimatwinUser?>.broadcast();
  ClimatwinUser? _currentUser;

  Stream<ClimatwinUser?> get authStateChanges => _authStateController.stream;
  ClimatwinUser? get currentUser => _currentUser;

  bool get isInitialized => _auth != null;
  bool get isFirebaseConnected => _auth != null;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isAnonymous ?? false;

  void initialize() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        // Immediate cold-start check to preserve signed-in user across launches
        if (_auth!.currentUser != null) {
          _currentUser = ClimatwinUser.fromFirebase(_auth!.currentUser!);
          _authStateController.add(_currentUser);
        }

        _auth!.authStateChanges().listen((User? user) {
          if (user != null) {
            _currentUser = ClimatwinUser.fromFirebase(user);
          } else {
            _currentUser = null;
          }
          _authStateController.add(_currentUser);
        });
      }
    } catch (e) {
      debugPrint('AuthService: Running in local/test mode ($e)');
    }
  }

  /// Human-friendly translation of FirebaseAuthException codes
  static String mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account registered with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please verify your credentials.';
        case 'invalid-credential':
          return 'Invalid email or password combination.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error: Unable to reach Firebase authentication servers.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again in a few moments.';
        case 'user-disabled':
          return 'This user account has been disabled by administrator.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled for this project.';
        default:
          return error.message ?? 'Authentication error (${error.code}).';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  Future<ClimatwinUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_auth != null) {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = ClimatwinUser.fromFirebase(credential.user!);
      _authStateController.add(_currentUser);
      return _currentUser!;
    }

    // Local / Offline demo authentication fallback
    _currentUser = ClimatwinUser(
      uid: 'demo_user_${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<ClimatwinUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_auth != null) {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = ClimatwinUser.fromFirebase(credential.user!);
      _authStateController.add(_currentUser);
      return _currentUser!;
    }

    // Local / Offline demo user creation
    _currentUser = ClimatwinUser(
      uid: 'demo_user_${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<ClimatwinUser> signInAnonymously() async {
    if (_auth != null) {
      final credential = await _auth!.signInAnonymously();
      _currentUser = ClimatwinUser.fromFirebase(credential.user!);
      _authStateController.add(_currentUser);
      return _currentUser!;
    }

    _currentUser = ClimatwinUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@climatwin.local',
      displayName: 'Guest Analyst',
      isAnonymous: true,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    if (_auth != null) {
      await _auth!.sendPasswordResetEmail(email: email);
      return;
    }
    debugPrint('AuthService: Simulated password reset email sent to $email');
  }

  Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
    _currentUser = null;
    _authStateController.add(null);
  }
}
