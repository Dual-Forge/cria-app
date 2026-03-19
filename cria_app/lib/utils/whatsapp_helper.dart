class WhatsAppHelper {
  static String generateThanksUrl({
    required String phone,
    required String nameOrNickname,
  }) {
    // Remove caracteres não numéricos do telefone
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.isEmpty) return '';

    // Formata a mensagem: Oi {nickname}, muito obrigado pelo presente! 💛
    final message = Uri.encodeComponent(
      "Oi $nameOrNickname, muito obrigado pelo presente! 💛"
    );

    return "https://wa.me/$cleanPhone?text=$message";
  }
}