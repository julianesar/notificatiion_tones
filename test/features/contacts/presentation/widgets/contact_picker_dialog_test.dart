import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_new_app/features/contacts/presentation/widgets/contact_picker_dialog.dart';
import 'package:my_new_app/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:my_new_app/features/contacts/domain/entities/contact.dart';
import 'package:my_new_app/features/contacts/domain/usecases/get_contacts.dart';
import 'package:my_new_app/features/contacts/domain/usecases/request_contacts_permission.dart';
import 'package:my_new_app/features/contacts/domain/repositories/contacts_repository.dart';

// Mock implementation for testing
class MockContactsRepository implements ContactsRepository {
  @override
  Future<List<Contact>> getContacts() async {
    return [
      const Contact(id: '1', name: 'John Doe', phoneNumber: '+1234567890'),
      const Contact(id: '2', name: 'Jane Smith', phoneNumber: '+0987654321'),
    ];
  }

  @override
  Future<bool> hasContactsPermission() async {
    return true;
  }

  @override
  Future<bool> requestContactsPermission() async {
    return true;
  }
}

void main() {
  group('ContactPickerDialog', () {
    late ContactsProvider contactsProvider;

    setUp(() {
      final mockRepository = MockContactsRepository();
      contactsProvider = ContactsProvider(
        getContacts: GetContacts(mockRepository),
        requestContactsPermission: RequestContactsPermission(mockRepository),
      );
    });

    testWidgets('displays contacts list correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ContactsProvider>(
          create: (_) => contactsProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ContactPickerDialog.show(
                    context: context,
                    title: 'Test Title',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the button to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog opens
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Buscar contacto...'), findsOneWidget);
      
      // Wait for contacts to load
      await tester.pump(const Duration(seconds: 1));

      // Verify contacts are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ContactsProvider>(
          create: (_) => contactsProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ContactPickerDialog.show(
                    context: context,
                    title: 'Test Title',
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Wait for contacts to load first
      await tester.pump(const Duration(seconds: 1));

      // Enter search query
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsNothing);
    });
  });
}