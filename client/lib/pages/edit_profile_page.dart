import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Page for editing user profile information (display name and avatar).
///
/// Reads current values from Firebase Auth and writes back on save.
/// Mobile: full-screen form with AppBar save action.
/// Desktop: top-centered card within the adaptive shell.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _errorMessage;

  // Photo state — picked image bytes for preview, null means unchanged.
  Uint8List? _pickedImageBytes;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final user = FirebaseAuth.instance.currentUser;
    final nameChanged =
        _nameController.text.trim() != (user?.displayName ?? '');
    return nameChanged || _pickedImageBytes != null || _photoRemoved;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktopSmall;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.sm),
            child: FilledButton(
              onPressed: _isSaving ? null : () => _handleSave(context),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopBody(context)
            : _buildMobileBody(context),
      ),
    );
  }

  // ===========================================================================
  // LAYOUT
  // ===========================================================================

  Widget _buildMobileBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: _buildForm(context),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _buildForm(context),
        ),
      ),
    );
  }

  // ===========================================================================
  // FORM
  // ===========================================================================

  Widget _buildForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(child: _buildAvatarEditor(context)),
          const SizedBox(height: Spacing.xl),

          // Error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(context),
            const SizedBox(height: Spacing.md),
          ],

          // Display name
          Text(
            'Display name',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Enter your name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name cannot be empty';
              }
              if (value.trim().length > 100) {
                return 'Name is too long';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.lg),

          // Email (read-only)
          Text(
            'Email',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            initialValue: _getEmail(),
            enabled: false,
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: IconSizes.medium,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Widget _buildAvatarEditor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 120.0;

    return GestureDetector(
      onTap: () => _showPhotoOptions(context),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarImage(context, size),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                size: IconSizes.small,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context, double size) {
    final colorScheme = Theme.of(context).colorScheme;

    final initialsWidget = Center(
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontSize: size * 0.35,
        ),
      ),
    );

    // Show picked image if available.
    if (_pickedImageBytes != null) {
      return Image.memory(
        _pickedImageBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => initialsWidget,
      );
    }

    // Show existing network photo if not removed.
    if (!_photoRemoved) {
      final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => initialsWidget,
        );
      }
    }

    return initialsWidget;
  }

  bool get _hasExistingPhoto {
    if (_photoRemoved) return false;
    if (_pickedImageBytes != null) return true;
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    return photoUrl != null && photoUrl.isNotEmpty;
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage();
              },
            ),
            if (_hasExistingPhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _pickedImageBytes = null;
                    _photoRemoved = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _pickedImageBytes = result.files.single.bytes;
          _photoRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open image picker')),
        );
      }
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Not signed in';
          _isSaving = false;
        });
        return;
      }

      final newName = _nameController.text.trim();

      // Update display name if changed.
      if (newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }

      // Update photo URL if removed.
      // Note: uploading a new photo requires a storage backend (Firebase Storage
      // or similar) which isn't configured yet. Picked images are shown as a
      // local preview but won't persist across devices until storage is set up.
      if (_photoRemoved) {
        await user.updatePhotoURL(null);
      }

      await user.reload();

      if (context.mounted) {
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Failed to update profile';
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile';
        _isSaving = false;
      });
    }
  }

  void _handleBack(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.pop();
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _getEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null || user!.email!.trim().isEmpty) {
      return 'No email provided';
    }
    return user.email!;
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
