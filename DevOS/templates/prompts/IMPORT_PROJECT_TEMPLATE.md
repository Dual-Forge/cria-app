# IMPORT PROJECT

## Objetivo

Sua função é transformar um projeto já existente em um projeto compatível com o DevOS.

O projeto já possui código-fonte desenvolvido.

Seu objetivo NÃO é modificar o código.

Seu objetivo é compreender completamente o projeto e gerar um PROJECT_BRIEF.md seguindo o padrão oficial do DevOS.

Após a aprovação do PROJECT_BRIEF pelo usuário, toda a documentação será gerada utilizando o generate_docs.md.

---

# Regras Obrigatórias

Após gerar o PROJECT_BRIEF e a documentação, grave todos os documentos na estrutura oficial do projeto.

Utilize os arquivos da pasta .devos apenas como referência.

Nunca gere documentação dentro da pasta .devos.

Leia completamente o projeto antes de escrever qualquer documento.

Nunca invente informações.

Caso alguma informação não possa ser inferida, utilize TODO.

Nunca altere código.

Nunca reorganize arquivos.

Nunca implemente melhorias.

Nunca faça refatorações.

Seu único objetivo é compreender o projeto.

---

# Ordem de Análise

Siga exatamente esta sequência.

## 1. Estrutura do Projeto

Identifique:

- Framework
- Linguagem
- Organização das pastas
- Arquitetura
- Padrões utilizados

---

## 2. Tecnologias

Identifique toda a stack.

Frontend

Backend

Banco

ORM

Infraestrutura

Serviços externos

Bibliotecas principais

---

## 3. Banco de Dados

Identifique:

- entidades
- relacionamentos
- migrations
- estratégias
- padrões

---

## 4. Módulos

Identifique todos os módulos existentes.

Explique resumidamente a responsabilidade de cada um.

---

## 5. Funcionalidades

Liste todas as funcionalidades implementadas.

Agrupe por módulo.

---

## 6. Fluxos

Identifique os principais fluxos do sistema.

Exemplo:

Login

Cadastro

Pedidos

Relatórios

etc.

---

## 7. APIs

Identifique:

- endpoints
- autenticação
- integrações
- webhooks

---

## 8. Regras de Negócio

Extraia todas as regras de negócio identificáveis.

Nunca invente regras.

---

## 9. Arquitetura

Explique:

- padrão arquitetural
- camadas
- responsabilidades
- dependências

---

## 10. Segurança

Identifique:

- autenticação
- autorização
- armazenamento de dados
- uploads
- logs

---

## 11. UX

Identifique padrões visuais.

Design System.

Responsividade.

Componentes.

---

## 12. Código

Avalie:

- organização
- qualidade
- padrões
- consistência

---

## 13. Dívida Técnica

Liste possíveis dívidas técnicas encontradas.

---

## 14. Pendências

Liste tudo aquilo que não foi possível identificar.

Utilize TODO quando necessário.

---

# Geração do PROJECT_BRIEF

Após concluir toda a análise, gere um PROJECT_BRIEF.md completo utilizando o template oficial do DevOS.

Todo o conteúdo deverá possuir origem nas evidências encontradas durante a análise.

Nunca invente funcionalidades.

Nunca suponha regras de negócio.

Nunca complete informações ausentes.

---

# Resultado Esperado

Ao finalizar, o usuário deverá possuir um PROJECT_BRIEF.md completo e pronto para revisão.

Após a aprovação do usuário, o projeto poderá utilizar normalmente o fluxo oficial do DevOS através do generate_docs.md.