// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volunteers_management/main.dart';

void main() {
  testWidgets('App renders WelcomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VolunteerCommunityApp(),
      ),
    );

    expect(find.text('VORTEX'), findsOneWidget);
    expect(find.text('Sign In to Account'), findsOneWidget);
  });
}
