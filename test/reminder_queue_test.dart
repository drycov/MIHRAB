import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/application/reminder_queue.dart';

void main() {
  test('operations never overlap and preserve order', () async {
    final queue = ReminderQueue();
    final gate = Completer<void>();
    final started = Completer<void>();
    final events = <String>[];
    final first = queue.run(() async {
      events.add('first-start');
      started.complete();
      await gate.future;
      events.add('first-end');
    });
    final second = queue.run(() async { events.add('second'); });
    await started.future;
    expect(events, ['first-start']);
    gate.complete();
    await Future.wait([first, second]);
    expect(events, ['first-start','first-end','second']);
  });
  test('queue recovers after failure', () async {
    final queue = ReminderQueue();
    final failed = queue.run<void>(() async { throw StateError('failure'); });
    final next = queue.run(() async => 42);
    await expectLater(failed, throwsStateError);
    expect(await next, 42);
  });
}
