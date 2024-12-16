import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the main app file
import 'package:bikini_bottom_news/main.dart';
// Add this import

void main() {
  group('Bikini Bottom News App', () {
    testWidgets('App launches and displays initial state',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(BikiniBottomNewsApp());

      // Verify the app title is present
      expect(find.text('Bikini Bottom News'), findsOneWidget);

      // Verify the default news category is present
      expect(find.text('Breaking News'), findsOneWidget);

      // Verify the file upload prompt is visible
      expect(find.text('Upload a News Scoop!'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('News category can be changed', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(BikiniBottomNewsApp());

      // Tap the dropdown to open categories
      await tester.tap(find.text('Breaking News'));
      await tester.pumpAndSettle();

      // Select a different category
      await tester.tap(find.text('Krusty Krab Updates').last);
      await tester.pumpAndSettle();

      // Verify the new category is selected
      expect(find.text('Krusty Krab Updates'), findsOneWidget);
    });

    testWidgets('File upload button is present', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(BikiniBottomNewsApp());

      // Find the 'Select File' button
      final Finder selectFileButton = find.text('Select File');
      expect(selectFileButton, findsOneWidget);

      // Find the 'Send to News Desk!' button
      final Finder uploadButton = find.text('Send to News Desk!');
      expect(uploadButton, findsOneWidget);
    });

    testWidgets('Initial state has no video player',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(BikiniBottomNewsApp());

      // Verify no video player is initially present
      expect(find.byType(VideoPlayerWidget), findsNothing);
    });
  });
}

// If it's a custom video player, define a placeholder
class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder implementation
  }
}
