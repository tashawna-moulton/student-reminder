import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- Controllers & state ---
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  String? _photoUrl;
  bool _busy = false;

  // --- Logout ---
  Future<void> _onLogout(BuildContext context) async {
    // Capture navigator & messenger BEFORE any await to avoid context-after-await lint
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final bool? safeToLogout = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (safeToLogout != true) return;

      await AuthService.instance.logout();

      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  // --- Update Profile ---
  Future<void> _updateProfile() async {
    setState(() => _busy = true);

    // Capture messenger BEFORE await
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uid = AuthService.instance.currentUser!.uid;
      await UserService.instance.updateMyProfile(
        uid,
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Upload/Select image ---
  Future<void> _onPickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final uid = AuthService.instance.currentUser!.uid;
    final bytes = await file.readAsBytes();
    await UserService.instance.uploadProfilePhoto(
      uid: uid,
      bytes: bytes,
      fileName: file.name,
    );
  }

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser!.uid;
    UserService.instance.getUser(uid).listen((doc) {
      final data = doc.data();
      if (data != null && mounted) {
        _firstName.text = (data['firstName'] ?? '') as String;
        _lastName.text = (data['lastName'] ?? '') as String;
        _bio.text = (data['bio'] ?? '') as String;
        _phone.text = (data['phone'] ?? '') as String;
        setState(() => _photoUrl = data['photoUrl'] as String?);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () => _onLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null ? const Icon(Icons.person, size: 30) : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            onPressed: _onPickPhoto,
            label: const Text('Change Image'),
          ),
          const SizedBox(height: 12),
          Text('Name: ${_firstName.text} ${_lastName.text} (set on register)'),
          Text('Email: ${user.email}'), // ← fixed label
          const SizedBox(height: 12),

          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone #'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _bio,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: _busy ? null : _updateProfile,
            child: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save/Update'),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () async {
              // Capture messenger BEFORE await to avoid context-after-await lint
              final messenger = ScaffoldMessenger.of(context);
              await AuthService.instance.sendPasswordReset(user.email!);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Password reset email sent!')),
              );
            },
            child: const Text('Send Password reset email'),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () async {
              // optional quick logout (kept simple)
              final navigator = Navigator.of(context);
              await AuthService.instance.logout();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
