// Facciata: sceglie l'implementazione in base alla piattaforma.
// - Mobile/desktop -> notification_service_native.dart (flutter_local_notifications)
// - Web            -> notification_service_web.dart (stub no-op)
export 'notification_service_native.dart'
    if (dart.library.html) 'notification_service_web.dart';
