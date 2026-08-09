# GENERATE DOCUMENTATION

# Local de Escrita

Antes de gerar qualquer documento:

1. Utilize os templates existentes dentro de .devos/templates apenas como modelo.

2. Nunca escreva documentos dentro da pasta .devos.

3. Todos os documentos gerados deverão ser escritos na raiz do projeto ou na pasta docs/.

4. Caso o arquivo já exista, atualize-o.

5. Caso não exista, crie-o na localização oficial.

A pasta .devos nunca deve conter a documentação oficial do projeto.

## Objetivo

Este documento define como a IA deve gerar automaticamente toda a documentação do projeto.

Seu objetivo é transformar o PROJECT_BRIEF em uma documentação completa, consistente e padronizada.

---

# Objetivo Principal

Após receber um PROJECT_BRIEF completamente preenchido, a IA deverá analisar todas as informações e preencher automaticamente todos os documentos presentes em `docs/`.

O usuário não deverá preencher manualmente cada documento.

O PROJECT_BRIEF é a única fonte inicial de informação.

---

# Ordem de Execução

A IA deverá seguir obrigatoriamente esta sequência.

1. Ler `PROJECT_BRIEF.md`.
2. Compreender completamente o projeto.
3. Identificar tecnologias.
4. Identificar regras de negócio.
5. Identificar módulos.
6. Identificar arquitetura.
7. Identificar fluxos.
8. Identificar integrações.
9. Identificar requisitos funcionais.
10. Identificar requisitos não funcionais.
11. Identificar riscos.
12. Identificar pendências.

Somente após compreender completamente o projeto deverá iniciar a geração dos documentos.

---

# Documentos que devem ser preenchidos

Gerar completamente:

- README.md
- VISION.md
- ROADMAP.md
- TECH_STACK.md
- ARCHITECTURE.md
- DATABASE.md
- BUSINESS_RULES.md
- DESIGN_SYSTEM.md
- DEVELOPMENT_GUIDE.md
- API_SPEC.md
- CODE_STYLE.md
- SECURITY.md
- TESTING.md
- ENVIRONMENT.md
- ERROR_HANDLING.md
- UX_RULES.md
- BACKLOG.md
- CHANGELOG.md
- TECH_DEBT.md

Também atualizar:

- PROJECT_STATUS.md
- PROJECT_TASKS.md

---

# Regras Obrigatórias

A IA deve:

Nunca inventar informações.

Nunca preencher campos sem evidências.

Sempre utilizar "TODO" quando alguma informação estiver ausente.

Nunca criar tecnologias que não estejam descritas.

Nunca alterar o escopo do projeto.

Nunca modificar decisões arquiteturais.

Nunca criar funcionalidades que não estejam previstas.

Sempre seguir os templates presentes em `templates/documents/`.

Sempre seguir os padrões definidos em `.ai/standards.md`.

---

# Qualidade da Documentação

Todos os documentos devem possuir:

- linguagem técnica;
- estrutura consistente;
- escrita profissional;
- organização clara;
- ausência de duplicidade;
- rastreabilidade entre documentos.

Cada documento deve possuir apenas informações relacionadas à sua responsabilidade.

Evite repetir o mesmo conteúdo em vários documentos.

---

# Consistência

Antes de finalizar, valide:

- todos os módulos possuem documentação;
- todas as regras possuem origem no PROJECT_BRIEF;
- tecnologias são consistentes;
- arquitetura é consistente;
- banco é consistente;
- nomenclaturas são consistentes;
- documentação não possui conflitos.

---

# Finalização

Ao concluir a geração, a IA deverá apresentar um relatório contendo:

## Documentos Gerados

Liste todos os documentos preenchidos.

---

## Informações Pendentes

Liste todos os itens marcados como TODO.

---

## Conflitos Encontrados

Liste inconsistências encontradas durante a geração.

---

## Recomendações

Apresente sugestões de melhoria antes do início do desenvolvimento.

---

## Resultado Esperado

Ao finalizar este processo, toda a documentação deverá estar pronta para que qualquer desenvolvedor ou IA inicie imediatamente a implementação do projeto sem necessidade de novas entrevistas com o usuário.  