import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salah/screens/home_screen.dart';

void main() {
  testWidgets('home screen renders the journal title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.text('Salah & Gratitude'), findsOneWidget);
  });
}
