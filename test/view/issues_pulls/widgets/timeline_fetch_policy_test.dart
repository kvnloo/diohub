import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_fetch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timeline automatic pagination', () {
    test('fetches only when idle and more pages exist', () {
      expect(
        shouldAutoFetchTimelinePage(
          hasMoreForward: true,
          phase: const PaginationPhase.idle(),
        ),
        isTrue,
      );
      expect(
        shouldAutoFetchTimelinePage(
          hasMoreForward: false,
          phase: const PaginationPhase.idle(),
        ),
        isFalse,
      );
    });

    test('forward failure waits for an explicit retry', () {
      expect(
        shouldAutoFetchTimelinePage(
          hasMoreForward: true,
          phase: PaginationPhase.failed(
            StateError('offline'),
            FetchDirection.forward,
          ),
        ),
        isFalse,
      );
    });

    test('backward failure does not trigger a forward fetch', () {
      expect(
        shouldAutoFetchTimelinePage(
          hasMoreForward: true,
          phase: PaginationPhase.failed(
            StateError('offline'),
            FetchDirection.backward,
          ),
        ),
        isFalse,
      );
    });

    test('loading phases never schedule duplicate forward fetches', () {
      for (final PaginationPhase phase in <PaginationPhase>[
        const PaginationPhase.loadingForward(),
        const PaginationPhase.loadingBackward(),
        const PaginationPhase.refreshing(),
      ]) {
        expect(
          shouldAutoFetchTimelinePage(hasMoreForward: true, phase: phase),
          isFalse,
        );
      }
    });
  });
}
