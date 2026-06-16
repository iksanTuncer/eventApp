// Pure unit tests that don't require Firebase initialization.
// Widget/integration tests that boot the full app need Firebase and a device,
// so they live elsewhere; these cover model + constant logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:event_app/models/app_event.dart';
import 'package:event_app/utils/constants.dart';

void main() {
  group('AppEvent.isEnded', () {
    test('returns true when endAt is in the past', () {
      final event = _buildEvent(
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        endAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(event.isEnded, isTrue);
    });

    test('returns false when endAt is in the future', () {
      final event = _buildEvent(
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(event.isEnded, isFalse);
    });
  });

  group('EventTypes.byKey', () {
    test('resolves a known type by key', () {
      expect(EventTypes.byKey('tea').label, EventTypes.tea.label);
    });

    test('falls back to "other" for an unknown key', () {
      expect(EventTypes.byKey('does_not_exist').key, EventTypes.other.key);
    });
  });

  group('RsvpStatus', () {
    test('exposes the three expected statuses', () {
      expect(RsvpStatus.pending, 'pending');
      expect(RsvpStatus.yes, 'yes');
      expect(RsvpStatus.no, 'no');
    });
  });
}

AppEvent _buildEvent({required DateTime startAt, required DateTime endAt}) {
  return AppEvent(
    eventId: 'e1',
    hostUid: 'u1',
    hostUsername: 'host',
    type: 'tea',
    title: 'Çay Buluşması',
    imageBase64: '',
    startAt: startAt,
    endAt: endAt,
    locationMode: 'text',
    locationText: 'Kadıköy',
  );
}
