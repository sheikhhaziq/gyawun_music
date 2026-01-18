import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gyawun/services/update_service/models/update_info.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Update Available'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${info.version}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: info.body.isNotEmpty
                    ? info.body
                    : '_No changelog provided._',
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium,
                  h1: theme.textTheme.titleLarge,
                  h2: theme.textTheme.titleMedium,
                  h3: theme.textTheme.titleSmall,
                  blockquoteDecoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  final uri = Uri.parse(href);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            final uri = Uri.parse(info.downloadUrl);

            await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
