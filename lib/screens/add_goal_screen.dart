import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class _GoalPreset {
  final String label;
  final String emoji;
  const _GoalPreset(this.label, this.emoji);
}

const _presets = [
  _GoalPreset('School supplies', '📚'),
  _GoalPreset('New shoes', '👟'),
  _GoalPreset('Phone accessory', '📱'),
  _GoalPreset('School event', '🎉'),
  _GoalPreset('Personal savings', '💰'),
];

const _emojiOptions = [
  '🎯', '🎧', '👟', '📱', '📚', '🎉', '💰', '🎮', '👜', '✈️', '🚲', '🎁',
];

const _sectionLabelStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppTheme.textDark,
);

class AddGoalScreen extends StatefulWidget {
  /// Pass an existing goal to edit its title/emoji/target instead of
  /// creating a new one.
  final SavingsGoal? existingGoal;

  const AddGoalScreen({super.key, this.existingGoal});

  bool get isEditing => existingGoal != null;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late String _selectedEmoji;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _targetController = TextEditingController(
      text: existing != null ? existing.targetAmount.toStringAsFixed(0) : '',
    );
    _selectedEmoji = existing?.emoji ?? _presets.first.emoji;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final target = double.parse(_targetController.text.trim());

    setState(() => _isSubmitting = true);

    final provider = context.read<BudgetProvider>();

    try {
      if (widget.isEditing) {
        await provider.updateGoal(
          id: widget.existingGoal!.id,
          title: title,
          emoji: _selectedEmoji,
          targetAmount: target,
        );
      } else {
        await provider.addGoal(
          title: title,
          emoji: _selectedEmoji,
          targetAmount: target,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Goal' : 'New Savings Goal'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              if (!isEditing) ...[
                const Text('Quick pick', style: _sectionLabelStyle),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _presets)
                      _PresetPill(
                        label: '${preset.emoji}  ${preset.label}',
                        selected: _titleController.text == preset.label,
                        onTap: () {
                          setState(() {
                            _titleController.text = preset.label;
                            _selectedEmoji = preset.emoji;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              const Text('Goal name', style: _sectionLabelStyle),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textDark,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. New headphones',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Give your goal a name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text('Choose an icon', style: _sectionLabelStyle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _emojiOptions)
                    _EmojiOption(
                      emoji: emoji,
                      selected: _selectedEmoji == emoji,
                      onTap: () => setState(() => _selectedEmoji = emoji),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              const Text('Target amount', style: _sectionLabelStyle),
              const SizedBox(height: 10),
              TextFormField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
                decoration: const InputDecoration(
                  prefixText: '₱  ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  hintText: '2000',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCBD6D2),
                  ),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid target amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(isEditing ? 'Save Changes' : 'Create Goal'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.12)
          : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppTheme.primary : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primaryDark : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiOption extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiOption({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}