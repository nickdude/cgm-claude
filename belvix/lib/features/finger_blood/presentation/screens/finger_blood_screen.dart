import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/edit_delete_menu.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/finger_blood_model.dart';
import '../providers/finger_blood_provider.dart';

class FingerBloodScreen
    extends StatefulWidget {
  const FingerBloodScreen({
    super.key,
  });

  @override
  State<FingerBloodScreen>
      createState() =>
          _FingerBloodScreenState();
}

class _FingerBloodScreenState
    extends State<FingerBloodScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              FingerBloodProvider>()
          .fetchFingerBloods();
    });
  }

  /// Opens the add/edit dialog. Pass [editing] to reuse the same form in
  /// edit mode (pre-filled, saves via the update API).
  void _openDialog({FingerBloodModel? editing}) {
    showDialog(
      context: context,
      builder: (_) => AddFingerBloodDialog(editing: editing),
    );
  }

  Future<void> _confirmDelete(FingerBloodModel item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Delete reading?",
      message:
          "This ${item.glucoseValue} mg/dL reading will be permanently removed. This can't be undone.",
    );

    if (!confirmed || !mounted) return;

    final ok = await context
        .read<FingerBloodProvider>()
        .deleteFingerBlood(item.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Reading deleted" : "Couldn't delete. Try again.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            FingerBloodProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Glucose Meter",
        ),
      ),

      body: provider.fingerBloods.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.water_drop_outlined,
                    title: 'No readings logged yet',
                    message:
                        'Your finger-stick readings will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.fingerBloods
                .length,

        itemBuilder: (
          context,
          index,
        ) {
          final item =
              provider
                  .fingerBloods[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.bloodtype,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        "${item.glucoseValue} mg/dL",

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(item.notes),
                    ],
                  ),
                ),

                Text(item.time),

                EditDeleteMenu(
                  onEdit: () => _openDialog(editing: item),
                  onDelete: () => _confirmDelete(item),
                ),
              ],
            ),
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddFingerBloodDialog
    extends StatefulWidget {
  const AddFingerBloodDialog({
    super.key,
    this.initialTime,
    this.editing,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  /// When set, the dialog opens in edit mode pre-filled with this record and
  /// saves via the update API instead of create.
  final FingerBloodModel? editing;

  @override
  State<AddFingerBloodDialog>
      createState() =>
          _AddFingerBloodDialogState();
}

class _AddFingerBloodDialogState
    extends State<AddFingerBloodDialog> {
  final glucoseController =
      TextEditingController();

  final notesController =
      TextEditingController();

  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();

    final editing = widget.editing;
    if (editing != null) {
      glucoseController.text = editing.glucoseValue.toString();
      notesController.text = editing.notes;
    }
  }

  @override
  void dispose() {
    glucoseController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final glucose = int.tryParse(glucoseController.text.trim());
    if (glucose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a glucose value")),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<FingerBloodProvider>();

    final ok = _isEditing
        ? await provider.updateFingerBlood(
            id: widget.editing!.id,
            glucoseValue: glucose,
            notes: notesController.text.trim(),
            loggedAt: widget.editing!.loggedAt,
          )
        : await provider.addFingerBlood(
            glucoseValue: glucose,
            notes: notesController.text.trim(),
            loggedAt: widget.initialTime,
          );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? "Couldn't update reading. Try again."
                : "Couldn't save reading. Try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing
            ? "Edit Glucose Meter Reading"
            : "Add Glucose Meter Reading",
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: glucoseController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Glucose Value",
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              hintText: "Notes",
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(
            _saving
                ? "Saving…"
                : (_isEditing ? "Update" : "Save"),
          ),
        ),
      ],
    );
  }
}