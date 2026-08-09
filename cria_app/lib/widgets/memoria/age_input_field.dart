import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipo de período usado no campo composto de idade do bebê.
enum AgePeriod { gestation, days, months, years }

extension AgePeriodX on AgePeriod {
  /// Rótulo exibido no dropdown.
  String get label => switch (this) {
    AgePeriod.gestation => 'Gestação',
    AgePeriod.days => 'Dias',
    AgePeriod.months => 'Meses',
    AgePeriod.years => 'Anos',
  };

  /// Limite superior razoável para o valor numérico de cada período.
  int get maxValue => switch (this) {
    AgePeriod.gestation => 42,
    AgePeriod.days => 730,
    AgePeriod.months => 120,
    AgePeriod.years => 18,
  };

  /// Pluralização simples: 1 unidade → singular, demais → plural.
  String unitLabel(int value) => value == 1 ? _singular : _plural;

  String get _singular => switch (this) {
    AgePeriod.gestation => 'semana',
    AgePeriod.days => 'dia',
    AgePeriod.months => 'mês',
    AgePeriod.years => 'ano',
  };

  String get _plural => switch (this) {
    AgePeriod.gestation => 'semanas',
    AgePeriod.days => 'dias',
    AgePeriod.months => 'meses',
    AgePeriod.years => 'anos',
  };
}

/// Converte o texto legado de idade (ex.: "3 Meses", "2 semanas", "5 dias")
/// para o par [AgePeriod] + valor numérico. Usado para popular a edição.
///
/// Retorna `(AgePeriod.months, 0)` quando não for possível interpretar.
(AgePeriod, int) parseLegacyAgeText(String? text) {
  if (text == null || text.trim().isEmpty) return (AgePeriod.months, 0);
  final lower = text.toLowerCase();

  int guess(String raw) {
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  if (lower.contains('gesta') || lower.contains('semana')) {
    return (AgePeriod.gestation, guess(lower));
  }
  if (lower.contains('dia')) return (AgePeriod.days, guess(lower));
  if (lower.contains('mês') || lower.contains('mes')) {
    return (AgePeriod.months, guess(lower));
  }
  if (lower.contains('ano')) return (AgePeriod.years, guess(lower));
  return (AgePeriod.months, guess(lower));
}

/// Campo composto de idade do bebê: um dropdown ([AgePeriod]) ao lado de um
/// input numérico. Gera o texto armazenado em `age_text` seguindo o padrão
/// legado do app (ex.: `"3 Meses"`, `"32 Semanas"`).
class AgeInputField extends StatefulWidget {
  final AgePeriod initialPeriod;
  final int initialValue;
  final ValueChanged<String>? onAgeTextChanged;

  const AgeInputField({
    super.key,
    this.initialPeriod = AgePeriod.months,
    this.initialValue = 0,
    this.onAgeTextChanged,
  });

  @override
  State<AgeInputField> createState() => _AgeInputFieldState();
}

class _AgeInputFieldState extends State<AgeInputField> {
  late AgePeriod _period;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _valueController = TextEditingController(
      text: widget.initialValue > 0 ? widget.initialValue.toString() : '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onAgeTextChanged?.call(currentAgeText);
  }

  void _setPeriod(AgePeriod next) {
    if (next == _period) return;
    setState(() => _period = next);
    _notify();
  }

  /// Texto da idade gerado a partir do estado atual ("3 Meses", "32 Semanas").
  String get currentAgeText {
    final value = int.tryParse(_valueController.text.trim()) ?? 0;
    return value > 0 ? '$value ${_period.unitLabel(value)}' : '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown do período
        Expanded(
          child: DropdownButtonFormField<AgePeriod>(
            initialValue: _period,
            decoration: InputDecoration(
              labelText: 'Período',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
            ),
            items: AgePeriod.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(p.label));
            }).toList(),
            onChanged: (v) {
              if (v != null) _setPeriod(v);
            },
          ),
        ),
        const SizedBox(width: 12),
        // Input numérico
        Expanded(
          child: TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => _notify(),
            decoration: InputDecoration(
              labelText: 'Valor',
              hintText: _period == AgePeriod.gestation ? 'ex: 32' : 'ex: 3',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}