// lib/features/communities/views/community_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/core/theme/app_theme.dart';
import 'package:volunteers_management/features/communities/views/create_community_screen.dart';
import 'package:volunteers_management/features/communities/views/join_community_screen.dart';

class CommunitySetupScreen extends ConsumerWidget {
  const CommunitySetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.hub_rounded, size: 36, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Get Started with a Community',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'To begin viewing live member maps and disaster operations, either create a volunteer brigade or join with an existing team code.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const Spacer(),

              // Card: Create Community
              _buildActionCard(
                context,
                icon: Icons.add_circle_outline_rounded,
                title: 'Create New Community',
                subtitle: 'Form a new volunteer group, generate unique invite codes & assign roles.',
                buttonText: 'Create Community',
                isPrimary: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Card: Join Community
              _buildActionCard(
                context,
                icon: Icons.group_add_outlined,
                title: 'Join with Code or QR',
                subtitle: 'Enter a 8-character team code (e.g. AVX-7K29P) or scan an invite QR.',
                buttonText: 'Join Existing Team',
                isPrimary: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinCommunityScreen()),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          isPrimary
              ? ElevatedButton(
                  onPressed: onTap,
                  child: Text(buttonText),
                )
              : OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
        ],
      ),
    );
  }
}
