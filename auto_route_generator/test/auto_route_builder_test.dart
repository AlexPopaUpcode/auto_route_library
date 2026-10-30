import 'package:auto_route_generator/src/builders/auto_route_builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

/// Fails the build step that asks for a resolver.
class _NoResolvers extends Resolvers {
  const _NoResolvers();

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) => throw StateError('Resolved ${buildStep.inputId}');
}

Future<TestBuilderResult> _build(Map<String, String> sources, {Resolvers? resolvers}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'app');
  await readerWriter.testing.loadIsolateSources();
  return testBuilder(
    AutoRouteBuilder(),
    sources,
    rootPackage: 'app',
    readerWriter: readerWriter,
    resolvers: resolvers,
    flattenOutput: true,
  );
}

void main() {
  test('finds a page declared in a part, and writes nothing for the part', () async {
    final result = await _build({
      'app|lib/pages.dart': "import 'package:auto_route/annotations.dart';\npart 'user_page.dart';",
      'app|lib/user_page.dart': "part of 'pages.dart';\n@RoutePage()\nclass UserPage {}",
    });

    expect(result.succeeded, isTrue);
    expect(result.outputs, [AssetId('app', 'lib/pages.route.json')]);
  });

  test('does not resolve files without the annotation', () async {
    final result = await _build({
      'app|lib/plain.dart': "import 'package:auto_route/annotations.dart';\nclass Plain {}",
      'app|lib/with_part.dart': "part 'with_part_part.dart';",
      'app|lib/with_part_part.dart': "part of 'with_part.dart';\nclass Part {}",
    }, resolvers: const _NoResolvers());

    expect(result.succeeded, isTrue);
    expect(result.outputs, isEmpty);
  });
}
