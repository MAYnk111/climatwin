import 'package:flutter_test/flutter_test.dart';
import 'package:climatwin_mobile/main.dart';

void main() {
  testWidgets('CLIMATWIN loads home screen and four bottom navigation items', (WidgetTester tester) async {
    await tester.pumpWidget(const ClimatwinApp());

    // Verify 4 primary navigation labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Intelligence'), findsOneWidget);
    expect(find.text('Simulate'), findsOneWidget);

    // Verify portfolio title
    expect(find.text('PORTFOLIO CLIMATE RISK'), findsOneWidget);
  });
}
