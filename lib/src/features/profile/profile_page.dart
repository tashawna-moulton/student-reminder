import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/user_service.dart';
import 'package:students_reminder/src/shared/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  
  Future<void> _onLogout(BuildContext context) async {
    try {
      //Confirm first
      final safeToLogout = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Yes'),
            ),
          ],
        ),
      );
      if (safeToLogout != true) return;
      await AuthService.instance.logout();
      MaterialPageRoute(builder: (_) => const LoginPage());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout Failed: $e')));
      }
    }
  }

  //Update Profile
  Future<void> _updateProfile() async {
    setState(() => _busy = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      await UserService.instance.updateMyProfile(
        uid,
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated!')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //Upload/Select and crop profile image
  Future<void> _onPickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    // Crop the image to square
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    final uid = AuthService.instance.currentUser!.uid;
    setState(() => _busy = true);
    try {
      await UserService.instance.uploadProfilePhoto(
        uid: uid,
        file: File(croppedFile.path),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //Upload/Select and crop cover image
  Future<void> _onPickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    // Crop the image to 16:9 aspect ratio for cover
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Cover Photo',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Cover Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    final uid = AuthService.instance.currentUser!.uid;
    setState(() => _busy = true);
    try {
      await UserService.instance.uploadCoverPhoto(
        uid: uid,
        file: File(croppedFile.path),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  String? _photoUrl;
  String? _coverUrl;
  bool _busy = false;

  // Character limits
  static const int _bioMaxLength = 300;
  static const int _phoneMaxLength = 15;

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
  void dispose() {
    _scrollController.dispose();
    _bio.dispose();
    _phone.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Widget _buildCharacterCounter(String text, int maxLength) {
    final currentLength = text.length;
    final isOverLimit = currentLength > maxLength;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        '$currentLength/$maxLength',
        style: TextStyle(
          fontSize: 12,
          color: isOverLimit ? Colors.red : Colors.grey[600],
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser!;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              title: Text('My Profile'),
              actions: [
                IconButton(
                  onPressed: () => _onLogout(context),
                  icon: Icon(Icons.logout),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover Image
                    _coverUrl != null
                        ? Image.network(
                            _coverUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                  Theme.of(context).primaryColor.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                    // Cover overlay with change button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _onPickCover,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                    // Profile picture overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: _onPickPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 37,
                                backgroundImage: _photoUrl != null
                                    ? NetworkImage(_photoUrl!)
                                    : null,
                                child: _photoUrl == null 
                                    ? Icon(Icons.person, size: 35) 
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 12),
            Text(
              '${_firstName.text} ${_lastName.text}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              user.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            // Phone field with character counter
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    errorText: _phone.text.length > _phoneMaxLength 
                        ? 'Phone number too long' 
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: _phoneMaxLength,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return _buildCharacterCounter(_phone.text, _phoneMaxLength);
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Bio field with character counter
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _bio,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    errorText: _bio.text.length > _bioMaxLength 
                        ? 'Bio too long' 
                        : null,
                  ),
                  maxLines: 4,
                  maxLength: _bioMaxLength,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return _buildCharacterCounter(_bio.text, _bioMaxLength);
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: (_busy || 
                         _bio.text.length > _bioMaxLength || 
                         _phone.text.length > _phoneMaxLength) 
                  ? null 
                  : _updateProfile,
              child: _busy 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save Profile'),
            ),
            
            SizedBox(height: 16),
            
            OutlinedButton(
              onPressed: () async {
                await AuthService.instance.sendPasswordReset(user.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent!')),
                  );
                }
              },
              child: Text('Send Password Reset Email'),
            ),
            
            SizedBox(height: 12),
            
            TextButton(
              onPressed: () => _onLogout(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}