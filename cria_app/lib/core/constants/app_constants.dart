/// AppConstants
///
/// Constantes globais do aplicativo Cria.
library;

class AppConstants {
  AppConstants._();

  // ── Gestação ──────────────────────────────────────────────────────────────

  static const int maxGestationalWeeks = 42;
  static const int fullTermWeeks = 40;
  static const int gestationDays = 280;

  // ── Família ───────────────────────────────────────────────────────────────

  static const int inviteCodeLength = 6;
  static const int maxThanksPerGift = 2;

  // ── Pagamento PIX ─────────────────────────────────────────────────────────

  static const Duration pixCountdown = Duration(minutes: 10);
  static const Duration pixPollingInterval = Duration(seconds: 3);

  // ── Checkout ──────────────────────────────────────────────────────────────

  static const int checkoutNameMinLength = 3;
  static const int checkoutPhoneMinLength = 10;
  static const int checkoutPhoneMaxLength = 11;
  static const int checkoutMessageMaxLength = 200;

  // ── Web Scraping ──────────────────────────────────────────────────────────

  static const Duration scrapingTimeout = Duration(seconds: 8);
}
