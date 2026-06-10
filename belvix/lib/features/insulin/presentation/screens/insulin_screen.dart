import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/edit_delete_menu.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/insulin_model.dart';
import '../providers/insulin_provider.dart';

class InsulinScreen
    extends StatefulWidget {
  const InsulinScreen({
    super.key,
  });

  @override
  State<InsulinScreen> createState() =>
      _InsulinScreenState();
}

class _InsulinScreenState
    extends State<InsulinScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              InsulinProvider>()
          .fetchInsulins();
    });
  }

  /// Opens the add/edit dialog. Pass [editing] to reuse the same form in
  /// edit mode (pre-filled, saves via the update API).
  void _openDialog({InsulinModel? editing}) {
    showDialog(
      context: context,
      builder: (_) => AddInsulinDialog(editing: editing),
    );
  }

  Future<void> _confirmDelete(InsulinModel insulin) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Delete insulin?",
      message:
          "This ${insulin.insulinType} dose will be permanently removed. This can't be undone.",
    );

    if (!confirmed || !mounted) return;

    final ok = await context
        .read<InsulinProvider>()
        .deleteInsulin(insulin.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Insulin deleted" : "Couldn't delete. Try again.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            InsulinProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Insulin"),
      ),

      body: provider.insulins.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.vaccines_outlined,
                    title: 'No insulin logged yet',
                    message:
                        'Your insulin doses will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.insulins.length,

        itemBuilder: (context, index) {
          final insulin =
              provider.insulins[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.purple.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.water_drop,
                        color: Colors.purple.shade700,
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
                        insulin
                            .insulinType,

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

                      Text(
                        "${insulin.dosage} Units",
                      ),
                    ],
                  ),
                ),

                Text(insulin.time),

                EditDeleteMenu(
                  onEdit: () => _openDialog(editing: insulin),
                  onDelete: () => _confirmDelete(insulin),
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

class AddInsulinDialog
    extends StatefulWidget {
  const AddInsulinDialog({
    super.key,
    this.initialTime,
    this.editing,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  /// When set, the dialog opens in edit mode pre-filled with this record and
  /// saves via the update API instead of create.
  final InsulinModel? editing;

  @override
  State<AddInsulinDialog>
      createState() =>
          _AddInsulinDialogState();
}

class _AddInsulinDialogState
    extends State<AddInsulinDialog> {
  static const _types = ["Rapid", "Long Acting"];

  final dosageController =
      TextEditingController();

  String insulinType = "Rapid";

  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();

    final editing = widget.editing;
    if (editing != null) {
      dosageController.text = editing.dosage.toString();
      // Guard against a stored type that isn't in the dropdown options.
      insulinType = _types.contains(editing.insulinType)
          ? editing.insulinType
          : _types.first;
    }
  }

  @override
  void dispose() {
    dosageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final dosage = int.tryParse(dosageController.text.trim());
    if (dosage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a dosage")),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<InsulinProvider>();

    final ok = _isEditing
        ? await provider.updateInsulin(
            id: widget.editing!.id,
            insulinType: insulinType,
            dosage: dosage,
            loggedAt: widget.editing!.loggedAt,
          )
        : await provider.addInsulin(
            insulinType: insulinType,
            dosage: dosage,
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
                ? "Couldn't update insulin. Try again."
                : "Couldn't save insulin. Try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Edit Insulin" : "Add Insulin"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField(
            initialValue: insulinType,
            items: const [
              DropdownMenuItem(
                value: "Rapid",
                child: Text("Rapid"),
              ),
              DropdownMenuItem(
                value: "Long Acting",
                child: Text("Long Acting"),
              ),
            ],
            onChanged: (value) {
              insulinType = value!;
            },
          ),

          const SizedBox(height: 20),

          TextField(
            controller: dosageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Dosage Units",
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