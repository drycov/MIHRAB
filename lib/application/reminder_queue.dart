import 'dart:async';

/// Single-isolate queue; failed operations do not poison subsequent work.
/// Background workers must not invoke the scheduler until a native ownership
/// mechanism is introduced.
class ReminderQueue {
  Future<void> _tail = Future<void>.value();
  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }
}
