import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:routerino/routerino.dart';

class SettingsTextField extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Widget> actions;
  final bool isDark;

  const SettingsTextField({
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.actions,
    required this.isDark,
    super.key,
  });

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: widget.isDark ? LinkDropColors.zinc800 : Colors.white,
              title: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : LinkDropColors.zinc900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: widget.actions,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: widget.controller,
                    textAlign: TextAlign.center,
                    onChanged: widget.onChanged,
                    autofocus: true,
                    onSubmitted: (_) => context.pop(),
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    t.general.confirm,
                    style: TextStyle(
                      color: LinkDropColors.teal500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.controller.text,
                style: TextStyle(
                  color: widget.isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: widget.isDark ? LinkDropColors.zinc500 : LinkDropColors.zinc400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
