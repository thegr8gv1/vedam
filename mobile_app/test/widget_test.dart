import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/main.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  testWidgets('VedamApp smoke test builds and displays Home Screen',
      (WidgetTester tester) async {
    final repository = ScriptureRepositoryImpl();
    final appState = AppState();

    await tester.pumpWidget(VedamApp(
      repository: repository,
      appState: appState,
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('VEDAM'), findsOneWidget);
    expect(find.text('वेदम्'), findsOneWidget);
  });
}
