import 'dart:async';

import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('explicit timeline pagination startup', () {
    test('ordinary timeline fetches once when explicitly started', () async {
      int forwardCalls = 0;
      final Completer<PaginatedResult<int>> pendingPage =
          Completer<PaginatedResult<int>>();
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: CursorBidirectionalSource<int>(
              forward: ({required int first, String? after}) {
                forwardCalls++;
                return pendingPage.future;
              },
              backward: ({required int last, String? before}) async =>
                  const PaginatedResult<int>(
                    items: <int>[],
                    hasNextPage: false,
                  ),
              anchor: (String itemId) async =>
                  const AnchorResult<int>(items: <int>[]),
            ),
            idOf: (int value) => '$value',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      // There is no constructor-queued request before the screen starts it.
      await Future<void>.delayed(Duration.zero);
      expect(forwardCalls, 0);

      final Future<void> fetch = controller.fetchForward();
      await Future<void>.delayed(Duration.zero);
      expect(forwardCalls, 1);
      expect(controller.state.value.phase, isA<LoadingForward>());

      pendingPage.complete(
        const PaginatedResult<int>(items: <int>[7], hasNextPage: false),
      );
      await fetch;
      await Future<void>.delayed(Duration.zero);
      expect(forwardCalls, 1);
      expect(controller.state.value.items, <int>[7]);
    });

    test(
      'comment anchor never launches a competing first-page request',
      () async {
        int forwardCalls = 0;
        int backwardCalls = 0;
        int anchorCalls = 0;
        final Completer<AnchorResult<int>> pendingAnchor =
            Completer<AnchorResult<int>>();
        final PaginationController<int, int> controller =
            PaginationController<int, int>(
              source: CursorBidirectionalSource<int>(
                forward: ({required int first, String? after}) async {
                  forwardCalls++;
                  return const PaginatedResult<int>(
                    items: <int>[1],
                    hasNextPage: false,
                  );
                },
                backward: ({required int last, String? before}) async {
                  backwardCalls++;
                  return const PaginatedResult<int>(
                    items: <int>[],
                    hasNextPage: false,
                  );
                },
                anchor: (String itemId) {
                  anchorCalls++;
                  expect(itemId, 'issuecomment-42');
                  return pendingAnchor.future;
                },
              ),
              idOf: (int value) => '$value',
              autoFetch: false,
            );
        addTearDown(controller.dispose);

        final Future<void> navigation = controller.navigateToAnchor(
          'issuecomment-42',
        );
        // Drain the microtask that would otherwise invoke the auto fetch.
        await Future<void>.delayed(Duration.zero);
        expect(anchorCalls, 1);
        expect(forwardCalls, 0);
        expect(backwardCalls, 0);

        pendingAnchor.complete(
          const AnchorResult<int>(
            items: <int>[42],
            hasMoreForward: false,
            hasMoreBackward: false,
          ),
        );
        await navigation;
        expect(controller.state.value.anchorId, 'issuecomment-42');
        expect(controller.state.value.items, <int>[42]);
        expect(forwardCalls, 0);
      },
    );

    test('failed anchor does not silently start a forward fetch', () async {
      int forwardCalls = 0;
      final Completer<AnchorResult<int>> pendingAnchor =
          Completer<AnchorResult<int>>();
      final PaginationController<int, int> controller =
          PaginationController<int, int>(
            source: CursorBidirectionalSource<int>(
              forward: ({required int first, String? after}) async {
                forwardCalls++;
                return const PaginatedResult<int>(
                  items: <int>[1],
                  hasNextPage: false,
                );
              },
              backward: ({required int last, String? before}) async =>
                  const PaginatedResult<int>(
                    items: <int>[],
                    hasNextPage: false,
                  ),
              anchor: (String itemId) => pendingAnchor.future,
            ),
            idOf: (int value) => '$value',
            autoFetch: false,
          );
      addTearDown(controller.dispose);

      final Future<void> navigation = controller.navigateToAnchor(
        'issuecomment-42',
      );
      await Future<void>.delayed(Duration.zero);
      pendingAnchor.completeError(StateError('no comment data'));
      await navigation;
      expect(controller.state.value.phase, isA<Failed>());
      expect(forwardCalls, 0);
    });
  });
}
