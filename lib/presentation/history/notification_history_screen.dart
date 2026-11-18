import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_history.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NotificationHistoryScreen({super.key, required this.onBack});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationHistoryProvider.notifier).loadHistory();
      await ref.read(notificationHistoryProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);
    final unreadCount =
        ref.read(notificationHistoryProvider.notifier).unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.black,
                                width: AppSpacing.borderWidth),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                            color: AppColors.surfaceContainerLowest,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTIFICATION HISTORY',
                              style: AppTypography.headlineLg
                                  .copyWith(color: AppColors.onSurface),
                            ),
                            if (unreadCount > 0)
                              Text(
                                '$unreadCount unread notification(s)',
                                style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                      if (history.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.done_all,
                              color: AppColors.primary),
                          tooltip: 'Mark all as read',
                          onPressed: () {
                            ref
                                .read(notificationHistoryProvider.notifier)
                                .markAllAsRead();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),

            // History List
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none,
                              size: 48, color: AppColors.outline),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No notification history records',
                            style: AppTypography.bodyLg
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenMargin),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final formattedTime =
                            DateFormat('MMM d, h:mm a').format(item.timestamp);
                        final isFirebase = item.channelId ==
                                NotificationConstants.channelGeneralUpdatesId ||
                            (item.payload != null &&
                                item.payload!.containsKey('source'));

                        final statusText = item.isTapped
                            ? 'Tapped'
                            : item.isDismissed
                                ? 'Dismissed'
                                : item.isRead
                                    ? 'Opened'
                                    : 'Unread';

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(notificationHistoryProvider.notifier)
                                  .markAsTapped(item.id);
                            },
                            child: NeuCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(
                                        top: 4, right: 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: item.isRead
                                          ? Colors.transparent
                                          : AppColors.primary,
                                      border: Border.all(
                                          color: item.isRead
                                              ? AppColors.outlineVariant
                                              : AppColors.primary,
                                          width: 1.5),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: AppTypography.bodyMd
                                                    .copyWith(
                                                  color: AppColors.onSurface,
                                                  fontWeight: item.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              formattedTime,
                                              style: AppTypography.labelSm
                                                  .copyWith(
                                                      color: AppColors
                                                          .onSurfaceVariant,
                                                      fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.body,
                                          style: AppTypography.labelSm
                                              .copyWith(
                                                  color: AppColors
                                                      .onSurfaceVariant),
                                        ),
                                        if (item.payload != null && item.payload!.containsKey('rule')) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rule: ${item.payload!['rule']} • Reason: ${item.payload!['reason'] ?? ''}',
                                            style: AppTypography.labelSm.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                        if (item.payload != null && item.payload!.containsKey('cancelled_reminders')) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Cancelled Pending Notifications: ${item.payload!['cancelled_reminders']}',
                                            style: AppTypography.labelSm.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // Source badge (Local vs Firebase)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isFirebase
                                                    ? Colors.orange.withValues(alpha: 0.15)
                                                    : AppColors.primaryContainer.withValues(alpha: 0.2),
                                                border: Border.all(
                                                    color: isFirebase ? Colors.orange : AppColors.primary,
                                                    width: 1),
                                              ),
                                              child: Text(
                                                isFirebase ? 'FIREBASE' : 'LOCAL',
                                                style: AppTypography.labelSm
                                                    .copyWith(
                                                        color: isFirebase ? Colors.orange : AppColors.primary,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Status badge (Scheduled/Delivered/Completed/Opened/Tapped/Dismissed/Unread)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceContainerLowest,
                                                border: Border.all(
                                                    color: AppColors.black,
                                                    width: 1),
                                              ),
                                              child: Text(
                                                (item.payload?['status']?.toString() ?? statusText).toUpperCase(),
                                                style: AppTypography.labelSm
                                                    .copyWith(
                                                        color: AppColors.onSurface,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    onPressed: () {
                                      ref
                                          .read(notificationHistoryProvider
                                              .notifier)
                                          .deleteItem(item.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                child: NeuButton.outline(
                  label: '🗑️ Clear All History',
                  isFullWidth: true,
                  onPressed: () {
                    ref
                        .read(notificationHistoryProvider.notifier)
                        .clearAll();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
