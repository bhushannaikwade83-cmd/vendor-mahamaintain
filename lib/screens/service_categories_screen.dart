import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../models/service_category_model.dart';
import '../repositories/service_category_repository.dart';
import '../widgets/app_toast.dart';

class ServiceCategoriesScreen extends ConsumerStatefulWidget {
  const ServiceCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServiceCategoriesScreen> createState() => _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends ConsumerState<ServiceCategoriesScreen> {
  final _repository = ServiceCategoryRepository();

  List<ServiceCategory> _categories = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? get _vendorId => ref.read(authRepositoryProvider).getCurrentUserId();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vendorId = _vendorId;
    if (vendorId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repository.fetchCategories(),
        _repository.fetchVendorCategoryIds(vendorId),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<ServiceCategory>;
        _selectedIds
          ..clear()
          ..addAll(results[1] as List<int>);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final vendorId = _vendorId;
    if (vendorId == null) return;

    if (_selectedIds.isEmpty) {
      showAppToast(context, 'Select at least one service category', type: ToastType.error);
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.saveVendorCategoryIds(vendorId, _selectedIds.toList());
      if (!mounted) return;
      showAppToast(context, 'Service categories saved', type: ToastType.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load service categories: $_error',
                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select every service you can repair. Vendors are matched to jobs based on this list.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _categories.map((category) {
                              final selected = _selectedIds.contains(category.id);
                              return InkWell(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(category.id);
                                  } else {
                                    _selectedIds.add(category.id);
                                  }
                                }),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 100,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.saffron50 : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected ? AppTheme.saffron : AppTheme.borderColor,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: category.imageUrl != null
                                                ? Image.network(
                                                    category.imageUrl!,
                                                    width: 80,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        _categoryImageFallback(),
                                                    loadingBuilder: (context, child, progress) {
                                                      if (progress == null) return child;
                                                      return _categoryImageFallback(loading: true);
                                                    },
                                                  )
                                                : _categoryImageFallback(),
                                          ),
                                          if (selected)
                                            const Positioned(
                                              top: -6,
                                              right: -6,
                                              child: Icon(Icons.check_circle, size: 20, color: AppTheme.saffron),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        category.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? AppTheme.saffronDark : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Save (${_selectedIds.length} selected)'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _categoryImageFallback({bool loading = false}) {
    return Container(
      width: 80,
      height: 64,
      color: AppTheme.bgLight,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.build_outlined, size: 22, color: AppTheme.textTertiary),
    );
  }
}
