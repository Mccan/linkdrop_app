import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/widget/glass/glass_dialog.dart';
import 'package:routerino/routerino.dart';

class ErrorDialog extends StatelessWidget {
  final String error;

  const ErrorDialog({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.dialogs.errorDialog.title),
        content: SelectableText(error),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(t.general.close),
          ),
        ],
      ),
    );
  }
}
