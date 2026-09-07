import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum ToastType { success, error, info }

class _ToastEntry {
  final String id;
  final Widget widget;
  _ToastEntry({required this.id, required this.widget});
}

/// A persistent overlay host that stacks toast/notification widgets above
/// the bottom navigation bar, mirroring the reference app's #toast-container.
class AppToastHost {
  AppToastHost._();

  static final ValueNotifier<List<_ToastEntry>> _entries = ValueNotifier([]);
  static OverlayEntry? _overlayEntry;

  static void _ensureHost(BuildContext context) {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return ValueListenableBuilder<List<_ToastEntry>>(
          valueListenable: _entries,
          builder: (ctx, list, _) {
            return Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: IgnorePointer(
                ignoring: list.isEmpty,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: list
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: e.widget,
                          ))
                      .toList(),
                ),
              ),
            );
          },
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  static String add(BuildContext context, Widget widget, {Duration? duration}) {
    _ensureHost(context);
    final id = DateTime.now().microsecondsSinceEpoch.toString() + widget.hashCode.toString();
    _entries.value = [..._entries.value, _ToastEntry(id: id, widget: widget)];
    if (duration != null) {
      Future.delayed(duration, () => remove(id));
    }
    return id;
  }

  static void remove(String id) {
    _entries.value = _entries.value.where((e) => e.id != id).toList();
  }

  static void clearAll() {
    _entries.value = [];
  }
}

Widget _toastCard({required Widget child, required Color color}) {
  return Material(
    color: Colors.transparent,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: child,
    ),
  );
}

void showAppToast(BuildContext context, String message, {ToastType type = ToastType.success}) {
  final Color bg;
  final IconData icon;
  switch (type) {
    case ToastType.success:
      bg = const Color(0xFF059669);
      icon = Icons.check_circle;
      break;
    case ToastType.error:
      bg = const Color(0xFFDC2626);
      icon = Icons.error;
      break;
    case ToastType.info:
      bg = AppTheme.saffron;
      icon = Icons.info;
      break;
  }

  final widget = _toastCard(
    color: bg,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  AppToastHost.add(context, widget, duration: const Duration(milliseconds: 3200));
}

void showRatingPromptToast(
  BuildContext context, {
  required String customerFirstName,
  required void Function(int rating) onRate,
}) {
  late String id;
  int? selected;

  final widget = StatefulBuilder(
    builder: (ctx, setState) {
      return Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.star, color: Color(0xFFF59E0B), size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rate your experience with $customerFirstName',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final filled = selected != null && star <= selected!;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selected = star);
                            onRate(star);
                            Future.delayed(const Duration(milliseconds: 650), () {
                              AppToastHost.remove(id);
                              showAppToast(context, 'Thank you for your feedback!', type: ToastType.success);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(Icons.star,
                                size: 26, color: filled ? const Color(0xFFF59E0B) : const Color(0xFFFCD34D)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    const Text('Your feedback helps improve service quality.',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  id = AppToastHost.add(context, widget, duration: const Duration(milliseconds: 8500));
}

void showPushNotificationToast(
  BuildContext context, {
  required String title,
  required String body,
  VoidCallback? onTakeAction,
}) {
  late String id;
  final widget = Material(
    color: Colors.transparent,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.gold]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(body, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 6),
                    const Text('Just now • Maha Maintain Pro Partner', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onTakeAction != null)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      AppToastHost.remove(id);
                      onTakeAction();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(color: AppTheme.saffron, borderRadius: BorderRadius.circular(16)),
                      child: const Text('Take Action',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              if (onTakeAction != null) const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => AppToastHost.remove(id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  id = AppToastHost.add(context, widget, duration: const Duration(milliseconds: 7500));
}

class NotificationItem {
  final IconData icon;
  final Color color;
  final Widget content;
  final VoidCallback? onTap;
  NotificationItem({required this.icon, required this.color, required this.content, this.onTap});
}

void showNotificationsPanel(BuildContext context, List<NotificationItem> items) {
  AppToastHost.clearAll();
  late String id;

  final widget = Material(
    color: Colors.transparent,
    child: Container(
      width: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                InkWell(
                  onTap: () => AppToastHost.remove(id),
                  child: Text('Clear all', style: TextStyle(color: AppTheme.saffron, fontSize: 12)),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: Column(
                children: items
                    .map((item) => InkWell(
                          onTap: () {
                            AppToastHost.remove(id);
                            item.onTap?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.icon, color: item.color, size: 16),
                                const SizedBox(width: 10),
                                Expanded(child: item.content),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  id = AppToastHost.add(context, widget, duration: const Duration(milliseconds: 9500));
}
