import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/trip_provider.dart';
import '../models/expense.dart';
import '../services/cloudinary_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/budget_alerts.dart';

class EditExpenseScreen extends StatefulWidget {
  final String tripId;
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.tripId,
    required this.expense,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _paidByController;
  final ImagePicker _imagePicker = ImagePicker();

  late String _selectedCategory;
  late String _selectedCurrency;
  late DateTime _selectedDate;
  bool _isLoading = false;

  // ✅ Receipt photo state
  XFile? _newReceiptImage; // New photo selected
  String? _existingReceiptUrl; // Existing photo URL
  bool _removeExistingPhoto = false; // Flag to remove existing photo
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing expense data
    _amountController =
        TextEditingController(text: widget.expense.amount.toString());
    _noteController = TextEditingController(text: widget.expense.note);
    _paidByController = TextEditingController(text: widget.expense.paidBy);
    _selectedCategory = widget.expense.categoryName;
    _selectedCurrency = widget.expense.currency;
    _selectedDate = widget.expense.expenseDate;
    _existingReceiptUrl = widget.expense.receiptImageUrl;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _paidByController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentMint,
              onPrimary: AppTheme.background,
              surface: AppTheme.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Show image source selection (Camera or Gallery)
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Receipt Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!kIsWeb) ...[
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppTheme.accentMint),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.accentMint),
              title: Text(kIsWeb ? 'Choose Photo' : 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newReceiptImage = pickedFile;
          _removeExistingPhoto = false; // Cancel remove if picking new
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _newReceiptImage = null;
      if (_existingReceiptUrl != null) {
        _removeExistingPhoto = true;
      }
    });
  }

  Widget _buildImagePreview() {
    // Show new image if selected
    if (_newReceiptImage != null) {
      return FutureBuilder<Uint8List>(
        future: _newReceiptImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
          return const Center(
            child: SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        },
      );
    }

    // Show existing image if available and not marked for removal
    if (_existingReceiptUrl != null && !_removeExistingPhoto) {
      return Image.network(
        _existingReceiptUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: AppTheme.background,
            child: const Center(
              child: Icon(Icons.broken_image,
                  size: 48, color: AppTheme.textSecondary),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? receiptImageUrl = _existingReceiptUrl;

        // Upload new image if selected
        if (_newReceiptImage != null) {
          setState(() {
            _isUploadingImage = true;
          });

          receiptImageUrl =
              await CloudinaryService.uploadImage(_newReceiptImage!);

          setState(() {
            _isUploadingImage = false;
          });

          if (receiptImageUrl == null) {
            throw Exception('Failed to upload receipt image');
          }
        } else if (_removeExistingPhoto) {
          // Remove photo if marked for removal
          receiptImageUrl = null;
        }

        final tripProvider = Provider.of<TripProvider>(context, listen: false);

        // Create updated expense
        final updatedExpense = widget.expense.copyWith(
          amount: double.parse(_amountController.text),
          currency: _selectedCurrency,
          categoryName: _selectedCategory,
          paidBy: _paidByController.text.trim(),
          expenseDate: _selectedDate,
          note: _noteController.text.trim(),
          receiptImageUrl: receiptImageUrl,
        );

        await tripProvider.updateExpense(
          widget.tripId,
          widget.expense.id,
          updatedExpense,
        );

        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.background),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Expense updated: ${AppConstants.getCurrencySymbol(_selectedCurrency)}${_amountController.text}' +
                          (receiptImageUrl != null ? ' 📸' : ''),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          await BudgetAlerts.checkBudgetStatus(context, widget.tripId);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating expense: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _deleteExpense() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        await tripProvider.deleteExpense(widget.tripId, widget.expense.id);

        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.background),
                  SizedBox(width: 12),
                  Text('Expense deleted'),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );

          BudgetAlerts.clearTripAlerts(widget.tripId);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting expense: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _newReceiptImage != null ||
        (_existingReceiptUrl != null && !_removeExistingPhoto);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Expense',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _deleteExpense,
                      icon:
                          const Icon(Icons.delete, color: AppTheme.errorColor),
                      tooltip: 'Delete',
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount and Currency Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money,
                              color: AppTheme.accentMint),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Amount required';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        dropdownColor: AppTheme.cardBackground,
                        items: AppConstants.currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              AppConstants.getCurrencySymbol(currency),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon:
                        Icon(Icons.category, color: AppTheme.accentMint),
                  ),
                  dropdownColor: AppTheme.cardBackground,
                  items: AppConstants.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Paid By Field
                TextFormField(
                  controller: _paidByController,
                  decoration: const InputDecoration(
                    labelText: 'Paid by *',
                    hintText: 'e.g., Me, John, Sarah',
                    prefixIcon: Icon(Icons.person, color: AppTheme.accentMint),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter who paid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date Picker
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today,
                          color: AppTheme.accentMint),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Receipt Photo Section
                Card(
                  color: AppTheme.background,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              color: AppTheme.accentMint,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Receipt Photo (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hasPhoto)
                          OutlinedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Add Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentMint,
                              side:
                                  const BorderSide(color: AppTheme.accentMint),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImagePreview(),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: _removePhoto,
                                      icon: const Icon(Icons.close),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change Photo'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes Field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Dinner at restaurant',
                    prefixIcon: Icon(Icons.note, color: AppTheme.accentMint),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploadingImage)
                        ? null
                        : _updateExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: AppTheme.background,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploadingImage
                                    ? 'Uploading receipt...'
                                    : 'Updating...',
                                style:
                                    const TextStyle(color: AppTheme.background),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Update Expense',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.background,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Accommodation':
        return Icons.hotel;
      case 'Entertainment':
        return Icons.movie;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFEF4444);
      case 'Transport':
        return const Color(0xFF3B82F6);
      case 'Shopping':
        return const Color(0xFFF59E0B);
      case 'Accommodation':
        return const Color(0xFF8B5CF6);
      case 'Entertainment':
        return const Color(0xFFEC4899);
      case 'Others':
        return AppTheme.textSecondary;
      default:
        return AppTheme.accentMint;
    }
  }
}
