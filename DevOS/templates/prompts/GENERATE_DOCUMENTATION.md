# GENERATE_DOCUMENTATION

## Objetivo

Sua responsabilidade é gerar toda a documentação técnica e funcional do projeto utilizando exclusivamente o conteúdo presente em **PROJECT_BRIEF.md**.

O PROJECT_BRIEF.md é a única fonte oficial de verdade do projeto.

Todos os documentos deverão ser consistentes entre si e representar fielmente o PROJECT_BRIEF.

O objetivo não é criar documentação bonita.

O objetivo é produzir documentação útil, consistente e suficiente para que qualquer desenvolvedor ou IA consiga implementar o projeto sem precisar consultar a conversa original.

---

# Entrada

Leia completamente:

- PROJECT_BRIEF.md

Leia também os templates localizados em:

templates/documents/

Cada documento deve seguir rigorosamente seu respectivo template.

---

# Documentos que devem ser gerados

Preencha todos os documentos existentes em:

docs/

Incluindo:

- README.md
- VISION.md
- ROADMAP.md
- BACKLOG.md
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
- ERROR_HANDLING.md
- ENVIRONMENT.md
- UX_RULES.md

Também preencha:

.ai/context.md

.ai/glossary.md

---

# Regras obrigatórias

Leia completamente o PROJECT_BRIEF antes de escrever qualquer documento.

Nunca escreva um documento parcialmente.

Todos os documentos devem ser coerentes entre si.

Nunca contradiga outro documento.

Nunca invente funcionalidades.

Nunca invente regras de negócio.

Nunca altere decisões arquiteturais.

Nunca altere tecnologias escolhidas.

Caso alguma informação esteja ausente:

Escreva TODO.

Nunca tente adivinhar.

Sempre que a mesma informação precisar aparecer em mais de um documento, mantenha a mesma terminologia e a mesma definição.

Nunca utilize nomes diferentes para representar a mesma entidade, funcionalidade ou conceito.

---

# Padronização

Todos os documentos devem seguir exatamente seus respectivos templates.

Não altere a estrutura dos templates.

Não remova seções.

Não crie novas seções, exceto quando forem explicitamente necessárias para organizar melhor o conteúdo.

---

# Consistência

Antes de finalizar:

Verifique se:

- Os módulos possuem o mesmo nome em todos os documentos.

- As regras de negócio são consistentes.

- As tecnologias são consistentes.

- A arquitetura está alinhada com o banco.

- O banco está alinhado com as regras de negócio.

- O roadmap contempla o MVP definido.

- O backlog contém apenas funcionalidades futuras.

---

# Qualidade

Escreva como um Software Architect Sênior.

Utilize linguagem técnica.

Evite repetições.

Evite textos genéricos.

Explique somente o necessário.

A documentação deve ser objetiva, completa e facilmente compreendida por desenvolvedores e IAs.

---

# Não faça

Não invente informações.

Não utilize conhecimento externo para complementar requisitos.

Não altere o escopo definido.

Não criar funcionalidades "porque seria interessante".

Não resumir o PROJECT_BRIEF.

Transforme o conteúdo em documentação estruturada.

---

# Saída esperada

Ao finalizar:

1. Todos os documentos em docs/ deverão estar preenchidos.

2. Atualize:

.ai/context.md

.ai/glossary.md

3. Gere um relatório contendo:

- Documentos preenchidos.
- Documentos que possuem TODO.
- Informações ausentes no PROJECT_BRIEF.
- Possíveis inconsistências encontradas.
- Recomendações de revisão para o usuário.

O relatório não deve alterar nenhum documento do projeto.