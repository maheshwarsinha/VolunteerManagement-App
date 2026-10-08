// lib/features/communities/views/create_community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/shared/views/main_shell_screen.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactController = TextEditingController();

  String _category = 'Disaster Relief';
  bool _requiresApproval = false;
  LocationVisibility _locationVisibility = LocationVisibility.allMembers;
  int _retentionDays = 30;

  bool _isSubmitting = false;
  CommunityModel? _createdCommunity;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final comm = await ref.read(communityProvider.notifier).createCommunity(
      name: _nameController.text.trim(),
      description: _descController.text.isNotEmpty ? _descController.text.trim() : null,
      category: _category,
      city: _cityController.text.isNotEmpty ? _cityController.text.trim() : null,
      contactInfo: _contactController.text.isNotEmpty ? _contactController.text.trim() : null,
      requiresApproval: _requiresApproval,
      locationVisibility: _locationVisibility,
      locationRetentionDays: _retentionDays,
    );

    setState(() {
      _isSubmitting = false;
      _createdCommunity = comm;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_createdCommunity != null) {
      return _buildSuccessScreen(_createdCommunity!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
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
                  'Community Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configure parameters and access policies for your new volunteer team.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Name
                _buildFieldLabel('Community Name *'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. ANCOME VORTEX',
                    prefixIcon: Icon(Icons.shield_outlined, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                _buildFieldLabel('Category'),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Disaster Relief', child: Text('Disaster Relief')),
                    DropdownMenuItem(value: 'Medical & First Aid', child: Text('Medical & First Aid')),
                    DropdownMenuItem(value: 'Campus Volunteers', child: Text('Campus Volunteers')),
                    DropdownMenuItem(value: 'Community Food Drive', child: Text('Community Food Drive')),
                    DropdownMenuItem(value: 'Event Logistics', child: Text('Event Logistics')),
                  ],
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 16),

                // City
                _buildFieldLabel('City / Headquarters'),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kanpur, Uttar Pradesh',
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildFieldLabel('Mission & Description'),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Brief summary of the goals and operations of this volunteer team...',
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 12),

                // Location Visibility Policy
                _buildFieldLabel('Location Visibility Policy'),
                Text(
                  'Control who within the community can observe volunteer coordinates on the live map.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LocationVisibility>(
                  value: _locationVisibility,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.visibility_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LocationVisibility.allMembers,
                      child: Text('All Community Members'),
                    ),
                    DropdownMenuItem(
                      value: LocationVisibility.adminsCoordinatorsOnly,
                      child: Text('Only Admins & Coordinators'),
                    ),
                    DropdownMenuItem(
                      value: LocationVisibility.teamMembersOnly,
                      child: Text('Only Assigned Team Members'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _locationVisibility = val!),
                ),
                const SizedBox(height: 16),

                // Location Retention Days
                _buildFieldLabel('Location History Retention (Days)'),
                DropdownButtonFormField<int>(
                  value: _retentionDays,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.history_toggle_off_rounded, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Days (Minimal Storage)')),
                    DropdownMenuItem(value: 30, child: Text('30 Days (Recommended Free Tier)')),
                    DropdownMenuItem(value: 90, child: Text('90 Days')),
                  ],
                  onChanged: (val) => setState(() => _retentionDays = val!),
                ),
                const SizedBox(height: 16),

                // Requires Approval Toggle
                SwitchListTile.adaptive(
                  value: _requiresApproval,
                  onChanged: (val) => setState(() => _requiresApproval = val),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Require Admin Approval to Join',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'When enabled, users who enter code must be approved by an admin before entering.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create & Generate Invite Code'),
                ),
                const SizedBox(height: 20),
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

  Widget _buildSuccessScreen(CommunityModel community) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle_rounded, size: 60, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                'Community Created!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code or QR code with your volunteers to allow them to join ${community.name}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Code Presentation Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'UNIQUE JOINING CODE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      community.code,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: community.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Code'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // QR Code representation
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'vortex://community/join?code=${community.code}',
                    version: QrVersions.auto,
                    size: 160.0,
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShellScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Open Community Map Dashboard'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
