import "package:flutter_test/flutter_test.dart";

import "package:pharmacy/main.dart";

void main() {
  testWidgets('renders login screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Sign In'), findsOneWidget);
  });
}
