import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Indikator 3 langkah pada proses pemulihan kata sandi (Email -> OTP -> Sandi)
class ForgotPasswordStepIndicator extends StatelessWidget {
  final int currentStep;

  const ForgotPasswordStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A2E1B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStepNode(stepIndex: 0, label: 'Email', icon: Icons.mail_outline_rounded),
          ),
          _buildStepDivider(isActive: currentStep >= 1),
          Expanded(
            child: _buildStepNode(stepIndex: 1, label: 'OTP', icon: Icons.shield_outlined),
          ),
          _buildStepDivider(isActive: currentStep >= 2),
          Expanded(
            child: _buildStepNode(stepIndex: 2, label: 'Sandi', icon: Icons.lock_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int stepIndex,
    required String label,
    required IconData icon,
  }) {
    final isDone = currentStep > stepIndex;
    final isCurrent = currentStep == stepIndex;

    Color bgColor = const Color(0xFFF3ECE3);
    Color iconColor = const Color(0xFFA09486);
    Color textColor = const Color(0xFFA09486);

    if (isCurrent) {
      bgColor = AppTheme.primary;
      iconColor = Colors.white;
      textColor = AppTheme.primaryDark;
    } else if (isDone) {
      bgColor = const Color(0xFFC07F35);
      iconColor = Colors.white;
      textColor = const Color(0xFFC07F35);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            size: 12,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.plusJakartaSans(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 10,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC07F35) : const Color(0xFFEADBCE),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
