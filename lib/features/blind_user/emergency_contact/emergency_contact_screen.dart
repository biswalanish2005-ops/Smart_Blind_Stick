import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/accessibility_utils.dart';
import '../../../models/emergency_contact.dart';
import '../../../providers/blind_user_provider.dart';
import '../../../widgets/accessible_button.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController(text: 'Caregiver');

  EmergencyContact? _editingContact;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BlindUserProvider>();
    final primary = provider.primaryContact;
    if (primary != null) {
      _setEditingContact(primary);
    }
  }

  void _setEditingContact(EmergencyContact contact) {
    setState(() {
      _editingContact = contact;
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _relationshipController.text = contact.relationship;
    });
  }

  void _clearForm() {
    setState(() {
      _editingContact = null;
      _nameController.clear();
      _phoneController.clear();
      _relationshipController.text = 'Caregiver';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BlindUserProvider>();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relationship = _relationshipController.text.trim();

    if (_editingContact != null) {
      final updated = _editingContact!.copyWith(
        name: name,
        phone: phone,
        relationship: relationship,
      );
      await provider.updateEmergencyContact(updated);
    } else {
      final newContact = EmergencyContact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        relationship: relationship,
        isPrimary: provider.emergencyContacts.isEmpty,
      );
      await provider.addEmergencyContact(newContact);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact $name saved successfully!'),
          backgroundColor: AppColors.safeGreen,
        ),
      );
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlindUserProvider>();
    final contacts = provider.emergencyContacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.emergencyContactTitle),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact Form Card
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingContact != null
                              ? AppStrings.editContact
                              : AppStrings.addContact,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.highVisYellow,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: _inputDecoration(
                            label: AppStrings.contactName,
                            icon: Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Phone Input
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: _inputDecoration(
                            label: AppStrings.contactPhone,
                            icon: Icons.phone,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (!EmergencyContact.isValidPhone(value.trim())) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Relationship Input
                        TextFormField(
                          controller: _relationshipController,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: _inputDecoration(
                            label: 'Relationship (e.g. Caregiver, Parent)',
                            icon: Icons.group,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AccessibleButton(
                          label: AppStrings.saveContact,
                          icon: Icons.save,
                          onPressed: _saveContact,
                        ),
                        if (_editingContact != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('Cancel Edit'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Configured Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (contacts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text(
                    AppStrings.noContactConfigured,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...contacts.map((contact) {
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: contact.isPrimary
                            ? AppColors.highVisYellow
                            : AppColors.borderLight,
                        width: contact.isPrimary ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: contact.isPrimary
                                    ? AppColors.highVisYellow
                                    : AppColors.surfaceElevated,
                                foregroundColor: contact.isPrimary
                                    ? Colors.black
                                    : AppColors.textPrimary,
                                child: Text(
                                  contact.name.isNotEmpty
                                      ? contact.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${contact.phone} • ${contact.relationship}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (contact.isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.highVisYellow,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRIMARY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(color: AppColors.borderLight, height: 24),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: AppColors.safeGreen,
                                    side: const BorderSide(color: AppColors.safeGreen),
                                  ),
                                  icon: const Icon(Icons.phone, size: 20),
                                  label: const Text('Call'),
                                  onPressed: () {
                                    AccessibilityUtils.dialPhoneNumber(contact.phone);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: AppColors.highVisYellow,
                                    side: const BorderSide(color: AppColors.highVisYellow),
                                  ),
                                  icon: const Icon(Icons.edit, size: 20),
                                  label: const Text('Edit'),
                                  onPressed: () => _setEditingContact(contact),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.dangerRed),
                                tooltip: 'Delete Contact',
                                onPressed: () {
                                  provider.deleteEmergencyContact(contact.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.highVisYellow),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.highVisYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dangerRed),
      ),
    );
  }
}
