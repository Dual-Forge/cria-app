# CODE STYLE

## Objetivo

Este documento define padrões de código obrigatórios para o projeto Cria.

---

# Backend de IA (Python)

- **Linguagem**: Python 3.
- **Tipagem**: Uso recomendado do Pydantic para declaração de modelos e tipos.
- **Tratamento de Exceções**: Blocos `try/except` cobrindo o scraping, utilizando instâncias da própria exceção para log.

# Frontend (Flutter)

- **Análise Estática**: Uso do `flutter_lints` padrão.
- **Organização**: Clean UI / Arquitetura por Features (`lib/features/`).
- **Nomenclatura**: Classes de UI terminando com `Screen` ou `Widget` (ex: `LoginScreen`, `BabyCardWidget`).

# Backend Edge (TypeScript / Deno)

- Uso padrão do Deno para Typescript.
- Funções exportadas puras onde possível para validação de webhooks.

---

# Pendências
- TODO: Formalizar os testes automatizados necessários (CI blocks) para cada PR de código.
