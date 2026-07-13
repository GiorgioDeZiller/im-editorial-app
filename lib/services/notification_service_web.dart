// Stub per il web: le notifiche locali non sono supportate nel browser.
// Tutti i metodi sono no-op così l'app web compila e funziona senza notifiche.
class NotificationService {
  static Future<void> init() async {}
  static Future<void> requestPermissions() async {}
  static Future<void> notifyNewProposals(int count) async {}
  static Future<void> notifySaved() async {}
  static Future<void> notifyGenerated(String type) async {}
}
