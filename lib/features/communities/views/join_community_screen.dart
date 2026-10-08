// lib/features/communities/views/join_community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/controllers/community_controller.dart';
import 'package:volunteers_management/features/communities/models/community_model.dart';
import 'package:volunteers_management/features/shared/views/main_shell_screen.dart';

class JoinCommunityScreen extends ConsumerStatefulWidget {
  const JoinCommunityScreen({super.key});

  @override
  ConsumerState<JoinCommunityScreen> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends ConsumerState<JoinCommunityScreen> {
  final _codeController = TextEditingController();
  CommunityModel? _previewCommunity;
  bool _isLoadingPreview = false;
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLookupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
      _previewCommunity = null;
    });

    try {
      final comm = await ref.read(communityProvider.notifier).previewCommunityByCode(code);
      setState(() {
        _isLoadingPreview = false;
        _previewCommunity = comm;
      });
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleConfirmJoin() async {
    if (_previewCommunity == null) return;

    setState(() => _isJoining = true);

    final success = await ref.read(communityProvider.notifier).joinCommunity(_previewCommunity!.id);

    setState(() => _isJoining = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_previewCommunity!.requiresApproval
              ? 'Join request submitted! Awaiting coordinator approval.'
              : 'Joined ${_previewCommunity!.name} successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Community'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Community Code',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Type the 8-character team code provided by your coordinator or scan the team QR.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Code Input & Search
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. AVX-7K29P',
                        prefixIcon: Icon(Icons.pin_outlined, size: 20),
                      ),
                      onChanged: (val) {
                        if (_previewCommunity != null) {
                          setState(() => _previewCommunity = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoadingPreview ? null : _handleLookupCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    ),
                    child: _isLoadingPreview
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Lookup'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // QR Code Alternative Action Button
              OutlinedButton.icon(
                onPressed: () {
                  // Simulate QR Scanner result or prefill code
                  setState(() {
                    _codeController.text = 'AVX-7K29P';
                  });
                  _handleLookupCode();
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan QR Code with Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],

              // Community Preview Card
              if (_previewCommunity != null) ...[
                const SizedBox(height: 28),
                Text(
                  'Community Found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.shield_rounded, color: AppColors.primary, size: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _previewCommunity!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_previewCommunity!.category} • ${_previewCommunity!.city ?? "Active"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_previewCommunity!.description != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _previewCommunity!.description!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Volunteers:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${_previewCommunity!.memberCount} Members',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Approval Policy:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            _previewCommunity!.requiresApproval ? 'Admin Review Required' : 'Instant Joining',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _previewCommunity!.requiresApproval ? AppColors.warning : AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      ElevatedButton(
                        onPressed: _isJoining ? null : _handleConfirmJoin,
                        child: _isJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_previewCommunity!.requiresApproval ? 'Submit Join Request' : 'Join Community'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
