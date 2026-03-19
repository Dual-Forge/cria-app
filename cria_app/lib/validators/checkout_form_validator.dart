class CheckoutFormValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome inválido (mínimo 3 caracteres)';
    }
    return null; // Válido
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp é obrigatório';
    }
    // Remove tudo que não for número (ex: parênteses, traços, espaços)
    final digits = value.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length < 10 || digits.length > 11) {
      return 'WhatsApp inválido (use DDD + número)';
    }
    return null; // Válido
  }

  static String? validateMessage(String? value) {
    if (value != null && value.length > 200) {
      return 'Mensagem muito longa (máximo 200 caracteres)';
    }
    return null; // Válido (é opcional)
  }
}