/// Formata um valor double para o padrão monetário brasileiro.
/// Exemplo: `formatBRL(1299.90)` → `'1299,90'`
/// Exemplo: `formatBRL(6.5)` → `'6,50'`
String formatBRL(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');
