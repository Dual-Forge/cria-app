# UX RULES

## Objetivo

Este documento define regras obrigatórias de experiência do usuário para o Cria.

---

# Fluxos de Cadastro e Interação

- **Zero Fricção de Presente**: A tela pública de presentes (Vitrine) para convidados não exige login ou criação de conta. Qualquer passo extra reduziria as taxas de conversão de doações. O convidado entra no link público `/presentes/:id`, escolhe o item e gera o Pix.
- **Velocidade e Feedback**: Processos envolvendo LLMs (extração de loja, dicas) podem demorar devido à latência de rede. A interface obrigatoriamente deve dispor de *loading indicators* clarificadores durante a comunicação com a API (via timeout configurado de até 10 segundos na API).

# Acessibilidade e Responsividade

- **Responsividade**: Apesar de ser focado na experiência Mobile App, o fluxo de presentes deve ser totalmente usável em navegadores web e desktop (através do GoRouter suportando links estáticos `/presentes/`), pois as contribuições normalmente ocorrem pela web (WhatsApp/Instagram Links).

---

# Pendências
- TODO: Estruturar guidelines específicas para leitores de tela em Flutter.
