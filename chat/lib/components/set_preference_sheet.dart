import 'package:flutter/material.dart';

enum FontSizeOption { small, medium, large }

class SetPreferenceSheet extends StatefulWidget {
  final FontSizeOption initialFontSize;
  final Future<void> Function(FontSizeOption fontSize) onSave;

  const SetPreferenceSheet({
    super.key,
    required this.initialFontSize,
    required this.onSave,
  });

  @override
  State<SetPreferenceSheet> createState() => _SetPreferenceSheetState();
}

class _SetPreferenceSheetState extends State<SetPreferenceSheet> {
  late FontSizeOption selectedFontSize;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedFontSize = widget.initialFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Font Size", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: FontSizeOption.values.map((option) {
              final label = option.name[0].toUpperCase() + option.name.substring(1);
              return ChoiceChip(
                label: Text(label),
                selected: selectedFontSize == option,
                onSelected: (_) => setState(() => selectedFontSize = option),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
              setState(() => isSaving = true);
              try {
                await widget.onSave(selectedFontSize);
                Navigator.pop(context);
              } finally {
                if (mounted) setState(() => isSaving = false);
              }
            },
            child: isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text("Save Preferences"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
