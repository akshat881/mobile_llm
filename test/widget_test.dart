import 'package:flutter_test/flutter_test.dart';
import 'package:lm_studio_mobile/main.dart';

void main() {
  testWidgets('LMStudioApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LMStudioApp());
    
    // Verify the app renders without errors
    expect(find.text('Model Discovery'), findsOneWidget);
  });
}
