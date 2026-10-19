import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/widgets/message_state.dart';
import 'package:emaskuid/widgets/sem_id.dart';
import 'package:emaskuid/widgets/skeleton_list.dart';
import 'package:flutter/material.dart';

/// Loading / error / empty handling in one place.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    required this.hasData,
    required this.onRetry,
    required this.child,
    this.error,
    this.emptyMessage = 'Belum ada data.',
  });

  final bool loading;
  final bool hasData;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (loading && !hasData) {
      return const SemId(TestIds.stateLoading, child: SkeletonList());
    }
    if (error != null && error!.isNotEmpty && !hasData) {
      return SemId(
        TestIds.stateError,
        child: MessageState(
          icon: Icons.cloud_off_rounded,
          title: 'Gagal memuat',
          message: error!,
          actionLabel: 'Coba lagi',
          onAction: onRetry,
        ),
      );
    }
    if (!hasData) {
      return SemId(
        TestIds.stateEmpty,
        child: MessageState(
          icon: Icons.inbox_rounded,
          title: 'Kosong',
          message: emptyMessage,
          actionLabel: 'Muat ulang',
          onAction: onRetry,
        ),
      );
    }
    return RefreshIndicator(onRefresh: () async => onRetry(), child: child);
  }
}
