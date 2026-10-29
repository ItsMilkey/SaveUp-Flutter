import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Eventos de sesión que consumirá el router (F1).
sealed class SessionEvent {
  const SessionEvent();
}

/// La sesión dejó de ser válida: hay que volver al login.
class SessionExpired extends SessionEvent {
  const SessionExpired();
}

/// Canal de eventos de sesión.
///
/// En F0 solo se emite [SessionExpired] (cuando el refresh falla o el reintento
/// vuelve a dar 401). La redirección del router es parte de F1.
class SessionEvents {
  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _controller.stream;

  void emitExpired() {
    if (!_controller.isClosed) {
      _controller.add(const SessionExpired());
    }
  }

  Future<void> dispose() => _controller.close();
}

final Provider<SessionEvents> sessionEventsProvider = Provider<SessionEvents>(
  (Ref ref) {
    final SessionEvents events = SessionEvents();
    ref.onDispose(() => unawaited(events.dispose()));
    return events;
  },
);
