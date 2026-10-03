import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Goal' : 'New Savings Goal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEditing) ...[
                Text(
                  'Quick pick',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _presets)
                      ActionChip(
                        avatar: Text(preset.emoji),
                        label: Text(preset.label),
                        onPressed: () {
                          setState(() {
                            _titleController.text = preset.label;
                            _selectedEmoji = preset.emoji;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              Text('Goal name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. New headphones',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Give your goal a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Icon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _EmojiPicker(
                selected: _selectedEmoji,
                onSelected: (emoji) => setState(() => _selectedEmoji = emoji),
              ),
              const SizedBox(height: 20),

              Text('Target amount', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                  hintText: '2000',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid target amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final target = double.parse(_targetController.text);

    setState(() => _isSubmitting = true);

    final provider = context.read<BudgetProvider>();

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
  }
}

const _emojiOptions = [
  '🎯', '🎧', '👟', '📱', '📚', '🎉', '💰', '🎮', '👜', '✈️', '🚲', '🎁',
];

class _EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _EmojiPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emoji in _emojiOptions)
          ChoiceChip(
            label: Text(emoji, style: const TextStyle(fontSize: 18)),
            selected: selected == emoji,
            onSelected: (_) => onSelected(emoji),
          ),
      ],
    );
  }
}