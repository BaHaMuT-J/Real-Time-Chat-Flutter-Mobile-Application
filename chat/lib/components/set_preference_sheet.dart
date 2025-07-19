import 'package:provider/provider.dart';
import 'package:chat/constant.dart';
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
  late int selectedThemeIndex;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedFontSize = widget.initialFontSize;

    final currentTheme = context.read<ThemeColorProvider>().theme;
    selectedThemeIndex = allThemeColors.indexOf(currentTheme);
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
          const Text("Color Theme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(allThemeColors.length, (index) {
              final theme = allThemeColors[index];
              final isSelected = index == selectedThemeIndex;

              return GestureDetector(
                onTap: () => setState(() => selectedThemeIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildColorDot(theme.colorShade1),
                      _buildColorDot(theme.colorShade2),
                      _buildColorDot(theme.colorShade3),
                      _buildColorDot(theme.colorShade4),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
              setState(() => isSaving = true);
              try {
                await widget.onSave(selectedFontSize);
                context.read<ThemeColorProvider>().setThemeByIndex(selectedThemeIndex);
                if (mounted) Navigator.pop(context);
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

  Widget _buildColorDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
