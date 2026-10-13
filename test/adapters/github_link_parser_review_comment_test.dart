import 'package:diohub/adapters/github_link_parser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHub PR review comment URLs', () {
    test('parses numeric review-comment anchor into an entity reference', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/owner/repo/pull/27#discussion_r123456'),
      );
      expect(parsed, isA<PRReviewCommentRef>());
      final comment = parsed! as PRReviewCommentRef;
      expect(comment.repo.owner, 'owner');
      expect(comment.repo.name, 'repo');
      expect(comment.prNumber, 27);
      expect(comment.commentId, 123456);
    });

    test('also accepts the pulls URL path variant', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/owner/repo/pulls/27#discussion_r42'),
      );
      expect(parsed, isA<PRReviewCommentRef>());
      expect((parsed! as PRReviewCommentRef).commentId, 42);
    });

    test('routes inline review comment links to Threads tab', () {
      final parsed =
          GitHubLinkParser.parse(
                Uri.parse(
                  'https://github.com/owner/repo/pull/27#discussion_r42',
                ),
              )!
              as PRReviewCommentRef;
      final route = parsed.toRoute() as PullRequestDetailRoute;
      expect(route.args!.pullRef.number, 27);
      expect(route.args!.initialIndex, 4);
    });

    test('plain PR links still open the default PR tab', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/owner/repo/pull/27'),
      );
      expect(parsed, isA<PullRequestRef>());
      final route =
          (parsed! as PullRequestRef).toRoute() as PullRequestDetailRoute;
      expect(route.args!.initialIndex, 0);
    });

    test('malformed review-comment fragment safely falls back to PR', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/owner/repo/pull/27#discussion_rinvalid'),
      );
      expect(parsed, isA<PullRequestRef>());
    });
  });
}
