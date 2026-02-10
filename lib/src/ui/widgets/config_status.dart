import 'package:flutter/material.dart';

class ConfigStatus extends StatelessWidget {
  const ConfigStatus({
    super.key,
    required this.microsoftConfigured,
    required this.googleConfigured,
  });

  final bool microsoftConfigured;
  final bool googleConfigured;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          microsoftConfigured
              ? 'Microsoft client ID configured.'
              : 'Missing Microsoft client ID in build environment.',
          style: TextStyle(
            color: microsoftConfigured
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          googleConfigured
              ? 'Google client ID configured.'
              : 'Missing Google client ID in build environment.',
          style: TextStyle(
            color: googleConfigured
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
