# TESTING

## Objetivo

Garantir a integridade do Cria antes de qualquer deploy em produção.

---

# Abordagens de Teste

- **Testes Unitários (Flutter)**: Verificação local dos calculadores de zodíaco, formatação de preços e lógicas estáticas (`test/utils/` e `test/validators/`).
- **Testes de Widget (Flutter)**: Garantir comportamento visual sem regressões (`test/widgets/`).
- **Testes de Serviço (Python/Mocking)**:
  - TODO: Testes unitários para o script FastAPI usando biblioteca como `pytest`.

---

# Ambientes

Todo teste integrado que necessitar invocar a API LLM (Gemini) deve mockar os retornos para evitar custo na API de produção (exemplo: arquivos como `test_gemini.dart` já implementam lógicas parciais, certifique-se de não subir mocks fixos na UI real).

---

# Pendências
- TODO: Estratégia oficial de E2E.
- TODO: Definição se `scripts_and_tests/test_webhook.js` são testes manuais ou se entrarão na esteira de CI.
