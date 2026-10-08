// lib/features/auth/views/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/auth/controllers/auth_controller.dart';
import 'package:volunteers_management/features/onboarding/views/location_permission_explanation_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Required Fields
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Optional Fields
  final _cityController = TextEditingController();
  final _volunteerIdController = TextEditingController();
  final _skillsController = TextEditingController();
  final _orgController = TextEditingController();
  final _emergencyController = TextEditingController();

  bool _obscurePassword = true;
  bool _showOptionalFields = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _volunteerIdController.dispose();
    _skillsController.dispose();
    _orgController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final success = await ref.read(authProvider.notifier).register(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      city: _cityController.text.isNotEmpty ? _cityController.text : null,
      volunteerId: _volunteerIdController.text.isNotEmpty ? _volunteerIdController.text : null,
      skills: skillsList,
      organization: _orgController.text.isNotEmpty ? _orgController.text : null,
      emergencyContact: _emergencyController.text.isNotEmpty ? _emergencyController.text : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LocationPermissionExplanationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Volunteer Network',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your unique identity to join emergency coordination and volunteer teams.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],

                // Full Name
                _buildFieldLabel('Full Name *'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Username
                _buildFieldLabel('Username * (Unique identifier)'),
                TextFormField(
                  controller: _usernameController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'e.g. rahul_volunteer',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    if (val.contains(' ')) return 'No spaces allowed in username';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                _buildFieldLabel('Email Address *'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'e.g. rahul@example.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || !val.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile
                _buildFieldLabel('Mobile Number *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Password
                _buildFieldLabel('Password * (Min 6 characters)'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildFieldLabel('Confirm Password *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Optional Information Accordion
                InkWell(
                  onTap: () => setState(() => _showOptionalFields = !_showOptionalFields),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _showOptionalFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showOptionalFields ? 'Hide Optional Profile Details' : 'Add Optional Profile Details (Skills, City, Org)',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showOptionalFields) ...[
                  const SizedBox(height: 12),
                  _buildFieldLabel('City / Region'),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(hintText: 'e.g. Kanpur, UP'),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Volunteer ID / Badge #'),
                  TextFormField(
                    controller: _volunteerIdController,
                    decoration: const InputDecoration(hintText: 'e.g. VOL-2026-99'),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Skills (Comma separated)'),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(hintText: 'First Aid, Drone Pilot, Logistics'),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('College / Organization'),
                  TextFormField(
                    controller: _orgController,
                    decoration: const InputDecoration(hintText: 'e.g. IIT Kanpur / Red Cross'),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Emergency Contact (Name & Phone)'),
                  TextFormField(
                    controller: _emergencyController,
                    decoration: const InputDecoration(hintText: 'e.g. Mother (+91 9811122233)'),
                  ),
                ],

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Complete Registration'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
