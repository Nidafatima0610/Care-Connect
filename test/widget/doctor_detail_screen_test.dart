import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect/features/doctors/data/doctor_repository.dart';
import 'package:care_connect/features/doctors/presentation/controllers/doctor_providers.dart';
import 'package:care_connect/features/doctors/presentation/doctor_detail_screen.dart';
import 'package:care_connect/core/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget({String doctorId = 'doc_alistair_vance'}) {
    return ProviderScope(
      overrides: [
        doctorRepositoryProvider.overrideWithValue(
          DoctorRepositoryImpl(latency: Duration.zero),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: DoctorDetailScreen(doctorId: doctorId),
      ),
    );
  }

  group('DoctorDetailScreen Widget Tests', () {
    testWidgets('Renders all clinical details, metrics, and actions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Dr. Alistair Vance'), findsWidgets);
      expect(find.text('Cardiology • MD, FACC'), findsOneWidget);
      expect(
        find.text('Interventional & Preventive Cardiology'),
        findsOneWidget,
      );

      // Metrics verification
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('14 Yrs'), findsOneWidget);
      expect(find.text('1850+'), findsOneWidget);

      // Section titles
      expect(find.text('About Specialist'), findsOneWidget);
      expect(find.text('Weekly Availability'), findsOneWidget);
      expect(find.text('Consultation Modalities'), findsOneWidget);
      expect(find.text('Clinic & Facility'), findsOneWidget);
      expect(find.text('Education & Credentials'), findsOneWidget);

      // Clinic and qualifications
      expect(
        find.text('CareConnect Metropolitan Health Center'),
        findsOneWidget,
      );
      expect(
        find.text('Doctor of Medicine (MD) - Harvard Medical School'),
        findsOneWidget,
      );

      // Sticky Bottom Bar & Fee
      expect(find.text('\$140'), findsOneWidget);
      expect(find.text('Book Appointment'), findsOneWidget);
    });

    testWidgets('Tapping Book Appointment opens Day 1 Roadmap modal', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Book Appointment button
      await tester.tap(find.text('Book Appointment'));
      await tester.pumpAndSettle();

      // Booking placeholder sheet is presented
      expect(find.text('Booking Engine Roadmap'), findsOneWidget);
      expect(find.text('Day 1 Scope'), findsOneWidget);
      expect(find.text('Acknowledge & Return to Directory'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Acknowledge & Return to Directory'));
      await tester.pumpAndSettle();

      expect(find.text('Booking Engine Roadmap'), findsNothing);
    });

    testWidgets(
      'Tapping favorite icon toggles state and shows SnackBar feedback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save Doctor'));
        await tester.pumpAndSettle();

        expect(
          find.text('Dr. Alistair Vance added to your saved physicians.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Shows not found state when doctorId does not exist', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(doctorId: 'invalid_id_999'));
      await tester.pumpAndSettle();

      expect(find.text('Physician Profile Not Found'), findsOneWidget);
      expect(find.text('Return to Directory'), findsOneWidget);
    });
  });
}
