import 'package:diohub/common/pagination/pagination_phase.dart';

/// Fetch the next timeline page automatically only while idle.
///
/// A failed request must wait for an explicit user retry, rather than
/// rescheduling itself every time the error state is built.
bool shouldAutoFetchTimelinePage({
  required bool hasMoreForward,
  required PaginationPhase phase,
}) => hasMoreForward && phase is Idle;
