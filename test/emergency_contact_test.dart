import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/emergency_contact.dart';

void main() {
  group('EmergencyContact Model Tests', () {
    test('Validates phone numbers properly', () {
      expect(EmergencyContact.isValidPhone('+1234567890'), isTrue);
      expect(EmergencyContact.isValidPhone('9876543210'), isTrue);
      expect(EmergencyContact.isValidPhone('+91 98765 43210'), isTrue);
      expect(EmergencyContact.isValidPhone('123'), isFalse);
      expect(EmergencyContact.isValidPhone('not-a-number'), isFalse);
      expect(EmergencyContact.isValidPhone(''), isFalse);
    });

    test('Serializes and deserializes correctly', () {
      final contact = EmergencyContact(
        id: 'c1',
        name: 'John Doe',
        phone: '+19876543210',
        relationship: 'Son',
        isPrimary: true,
      );

      final json = contact.toJson();
      final revived = EmergencyContact.fromJson(json);

      expect(revived.id, contact.id);
      expect(revived.name, contact.name);
      expect(revived.phone, contact.phone);
      expect(revived.relationship, contact.relationship);
      expect(revived.isPrimary, isTrue);
    });
  });
}
