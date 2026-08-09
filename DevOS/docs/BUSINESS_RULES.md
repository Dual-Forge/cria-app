# BUSINESS RULES

## Objetivo

Este documento centraliza todas as regras de negócio do Cria.

---

# Regras de Negócio

## Saúde e Monitoramento

### BPM_LIMITE
- **Descrição**: O BPM registrado do bebê deve estar restrito ao limite aceitável.
- **Motivo**: Prevenção de inputs irracionais por erro de digitação dos pais.
- **Impacto**: O banco de dados (`baby_profile`) impõe check de `>= 40 AND <= 200`.

### UNICIDADE_BEBE
- **Descrição**: Cada família pode ter apenas um perfil de bebê atualmente.
- **Motivo**: O escopo do MVP prevê a gestão de um bebê (ou um perfil centralizado gestacional) por vez.
- **Impacto**: Restrição de chave única em `baby_profile(family_id)`.

## Lista de Presentes e Preços

### PRECO_A_VISTA
- **Descrição**: A extração de preços da IA deve ignorar parcelamentos e buscar estritamente o valor do produto à vista.
- **Motivo**: Como a contribuição feita pelo convidado será via transferência direta (Pix), não cabem taxas de juros ou parcelamentos ao recebedor.
- **Impacto**: O prompt do Gemini explicitamente instrui a eliminação de strings do tipo "12x de" ou preços riscados de promoções anteriores.

### STATUS_PRESENTE
- **Descrição**: Um presente pode estar em um dos 3 estados: `available`, `reserved`, `received`.
- **Motivo**: Organizar o fluxo de recebimento e evitar duplicação de pagamentos num mesmo item único.
- **Impacto**: Impõe check no banco de dados na coluna `gift_status`.

---

# Pendências
- TODO: Definir regras formais de timeout para invalidação da reserva de um item ('reserved' voltando para 'available') caso o Pix do Mercado Pago não seja pago em tempo hábil.
