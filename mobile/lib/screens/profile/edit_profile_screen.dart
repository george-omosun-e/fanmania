import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _avatarUrlController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');

    _displayNameController.addListener(_onFieldChanged);
    _avatarUrlController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final user = context.read<AuthProvider>().currentUser;
    final hasChanges = _displayNameController.text != (user?.displayName ?? '') ||
        _avatarUrlController.text != (user?.avatarUrl ?? '');
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_onFieldChanged);
    _avatarUrlController.removeListener(_onFieldChanged);
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  String? _validateDisplayName(String? value) {
    if (value != null && value.isNotEmpty && value.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (value != null && value.length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  String? _validateAvatarUrl(String? value) {
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.isAbsolute) {
        return 'Please enter a valid URL';
      }
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final displayName = _displayNameController.text.trim();
    final avatarUrl = _avatarUrlController.text.trim();

    final success = await authProvider.updateProfile(
      displayName: displayName.isNotEmpty ? displayName : null,
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return TextButton(
                onPressed: auth.isLoading || !_hasChanges ? null : _handleSave,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.electricCyan,
                        ),
                      )
                    : Text(
                        'Save',
                        style: AppTypography.labelLarge.copyWith(
                          color: _hasChanges
                              ? AppColors.electricCyan
                              : AppColors.textTertiary,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar preview
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: AppColors.cyanGlow,
                      ),
                      child: Center(
                        child: Text(
                          (user?.displayName ?? user?.username ?? 'F')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.deepSpace,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '@${user?.username ?? 'username'}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Display name field
              Text(
                'Display Name',
                style: AppTypography.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                validator: _validateDisplayName,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter your display name',
                  helperText: 'This is how other users will see you',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar URL field
              Text(
                'Avatar URL',
                style: AppTypography.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _avatarUrlController,
                validator: _validateAvatarUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'https://example.com/avatar.png',
                  helperText: 'Enter a URL for your profile picture',
                  prefixIcon: const Icon(Icons.link_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ghostBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your username cannot be changed after registration.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
