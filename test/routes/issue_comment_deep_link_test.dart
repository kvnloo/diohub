import 'package:diohub/adapters/github_link_parser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('issue comment deep links', () {
    test('preserves an issue comment anchor through routing', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse(
          'https://github.com/example/project/issues/12#issuecomment-345',
        ),
      );
      expect(parsed, isA<IssueCommentRef>());

      final route = (parsed! as IssueCommentRef).toRoute();
      expect(route, isA<IssueDetailRoute>());
      final args = (route as IssueDetailRoute).args!;
      expect(args.issueRef.repo.owner, 'example');
      expect(args.issueRef.repo.name, 'project');
      expect(args.issueRef.number, 12);
      expect(args.scrollToCommentId, 'issuecomment-345');
    });

    test('plain issue link has no selected comment', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/example/project/issues/12'),
      );
      expect(parsed, isA<IssueRef>());
      final route = (parsed! as IssueRef).toRoute() as IssueDetailRoute;
      expect(route.args!.scrollToCommentId, isNull);
    });

    test('malformed comment fragment does not produce a comment route', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse(
          'https://github.com/example/project/issues/12#issuecomment-nope',
        ),
      );
      expect(parsed, isA<IssueRef>());
    });
  });
}
