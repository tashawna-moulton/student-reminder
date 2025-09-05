import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
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


  //Upload/Select image
  Future<void> _onPickPhoto({bool isCover = false}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    File? files = File(file.path);
    files = await _cropImage(file: files);
    if (files == null) return;

    final uid = AuthService.instance.currentUser!.uid;
    
    if (isCover == true) {
      await UserService.instance.uploadProfileCover(
        uid: uid,
        file: File(files.path),
      );
  }else {
    await UserService.instance.uploadProfilePhoto(
      uid: uid,
      file: File(files.path),
    );
  }
  }

  Future<File?> _cropImage({required File file}) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
    );
    if (croppedImage == null) return null;
    return File(croppedImage.path);
  }

  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final int maxtextLength = 100;
  String? _photoUrl;
  String? _coverUrl;
  bool _busy = false;

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
        setState(() {
          _photoUrl = data['photoUrl'] as String?;
          _coverUrl = data['coverUrl'] as String?;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 220,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _coverUrl != null
                  ? Image.network(_coverUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey),
            ),
            title: Text('My Profile'),
            actions: [
              IconButton(
                onPressed: () => _onLogout(context),
                icon: Icon(Icons.logout),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.camera_alt),
                    onPressed: _onPickPhoto,
                    label: Text('Change Image'),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.photo_size_select_actual_sharp),
                    onPressed: () => _onPickPhoto(isCover: true),
                    label: Text('Change Cover'),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Name: ${_firstName.text} ${_lastName.text} (set on register)',
                  ),
                  Text('Email: ${user.email}'),
                  SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    decoration: InputDecoration(labelText: 'Phone #'),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _bio,
                    maxLength: maxtextLength,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      counter: Text('${_bio.text.length}/$maxtextLength'),
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _busy ? null : _updateProfile,
                    child: _busy
                        ? CircularProgressIndicator()
                        : Text('Save/Update'),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await AuthService.instance.sendPasswordReset(user.email!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Password reset email sent!')),
                        );
                      }
                    },
                    child: Text('Send Password reset email'),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await AuthService.instance.logout();
                    },
                    child: Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}