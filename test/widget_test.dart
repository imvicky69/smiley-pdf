import 'package:flutter_test/flutter_test.dart';
import 'package:smiley_pdf/app.dart';
import 'package:smiley_pdf/core/constants/app_constants.dart';

void main() {
  testWidgets('SmileyPdfApp renders home screen with app name and open button', (WidgetTester tester) async {
    await tester.pumpWidget(const SmileyPdfApp());
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text('Open PDF'), findsOneWidget);
  });
}
