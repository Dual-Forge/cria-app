# GENERATE PROJECT BRIEF

## Objetivo

Sua responsabilidade é transformar toda a conversa realizada com o usuário em um documento chamado **PROJECT_BRIEF.md**.

Este documento será a **única fonte oficial de verdade do projeto**.

Toda a documentação futura, todos os agentes de IA e toda a implementação deverão ser baseados exclusivamente neste documento.

Seu objetivo não é resumir a conversa.

Seu objetivo é transformar uma conversa em uma especificação funcional, técnica e estratégica completa.

---

# Antes de iniciar

Antes de analisar a conversa, considere que este projeto utiliza o **Framework DevOS**.

O DevOS possui um fluxo oficial de desenvolvimento.

O PROJECT_BRIEF representa a primeira etapa desse fluxo.

Toda a documentação do projeto será gerada posteriormente utilizando exclusivamente este documento.

Portanto:

- O PROJECT_BRIEF deve ser completo.
- Não deixe decisões importantes implícitas.
- Não faça referências à conversa.
- Escreva como se a conversa nunca tivesse existido.
- O documento deve ser totalmente autossuficiente.

---

# Papel do PROJECT_BRIEF

O PROJECT_BRIEF será utilizado posteriormente para:

- gerar toda a documentação do projeto;
- orientar desenvolvedores;
- orientar agentes de IA;
- gerar arquitetura;
- gerar regras de negócio;
- gerar roadmap;
- gerar backlog;
- gerar documentação técnica;
- orientar futuras implementações.

Todo conhecimento importante discutido durante a conversa deverá estar presente neste documento.

---

# Seu papel

Aja simultaneamente como:

- Product Manager Sênior
- Product Owner
- Analista de Negócios
- Software Architect Sênior
- Tech Lead
- UX Designer (para definição dos fluxos)
- QA Analyst (identificando ambiguidades e informações faltantes)

---

# Pensamento antes da escrita

Antes de escrever qualquer linha do PROJECT_BRIEF, leia toda a conversa do início ao fim e construa internamente um modelo completo do projeto.

Somente após compreender integralmente o contexto inicie a escrita.

Antes de começar, confirme internamente que consegue responder:

- Qual é o objetivo do projeto?
- Qual problema ele resolve?
- Quem utilizará o sistema?
- Como o sistema deverá funcionar?
- Quais decisões importantes foram tomadas?
- O MVP está claramente definido?
- Existem conflitos entre requisitos?
- Existem informações ausentes?

Caso ainda existam dúvidas, registre-as posteriormente na seção **Pendências**.

---

# Regras obrigatórias

Leia toda a conversa antes de começar a escrever.

Nunca gere o documento parcialmente.

Nunca invente funcionalidades.

Nunca assuma comportamentos que não tenham sido discutidos.

Nunca invente regras de negócio.

Nunca invente decisões arquiteturais.

Nunca complete lacunas por conta própria.

Quando existir alguma dúvida, não tente resolvê-la sozinho.

Crie uma seção chamada **Pendências** contendo perguntas objetivas para o usuário responder posteriormente.

Sempre prefira detalhar ao invés de resumir.

Explique o motivo das decisões tomadas durante a conversa quando elas forem importantes para o projeto.

Utilize linguagem técnica, clara e profissional.

Escreva como um arquiteto de software experiente preparando documentação para uma equipe de desenvolvimento.

Sempre que uma decisão tomada durante a conversa impactar:

- arquitetura;
- banco de dados;
- regras de negócio;
- segurança;
- escalabilidade;
- experiência do usuário;
- integrações;
- infraestrutura;

registre explicitamente essa decisão e sua justificativa no PROJECT_BRIEF.

Nunca trate decisões importantes como detalhes implícitos.

---

# O documento deve permitir responder às seguintes perguntas

- O que é este projeto?
- Qual problema ele resolve?
- Quem utilizará o sistema?
- Quais são os tipos de usuários?
- Quais funcionalidades existirão?
- Como cada funcionalidade deverá funcionar?
- Quais regras de negócio devem ser respeitadas?
- Qual é o MVP?
- O que ficará para versões futuras?
- Quais tecnologias já foram definidas?
- Quais decisões arquiteturais foram tomadas?
- Quais integrações existirão?
- Quais restrições existem?
- Quais riscos conhecidos existem?
- Quais dependências existem?
- Quais informações ainda precisam ser definidas?

---

# Nível de Detalhamento

Sempre documente:

- decisões;
- justificativas;
- restrições;
- exceções;
- dependências;
- riscos conhecidos;
- alternativas descartadas (quando discutidas).

Nunca trate decisões importantes como conhecimento implícito.

---

# Não faça

Não escreva textos de marketing.

Não utilize linguagem comercial.

Não utilize frases motivacionais.

Não escreva "talvez", "provavelmente", "imagina-se" ou qualquer linguagem especulativa.

Não invente funcionalidades para preencher lacunas.

Não copie trechos da conversa.

Não utilize linguagem informal.

Organize o conhecimento adquirido.

---

# Qualidade Esperada

O PROJECT_BRIEF deverá ser suficiente para que outra IA consiga gerar toda a documentação do projeto sem precisar ler a conversa original.

Caso isso não seja possível, considere que o documento ainda está incompleto.

---

# Critério de Aceitação

Antes de finalizar, valide internamente que:

✅ Outro desenvolvedor entenderia completamente o projeto apenas lendo este documento.

✅ Outra IA conseguiria gerar toda a documentação do DevOS utilizando apenas este documento.

✅ Nenhuma decisão importante ficou apenas na conversa.

✅ Não existem ambiguidades conhecidas sem estarem listadas em **Pendências**.

✅ O documento está consistente do início ao fim.

---

# Resultado esperado

Ao finalizar, gere apenas o conteúdo completo do arquivo **PROJECT_BRIEF.md**, seguindo rigorosamente o template definido em:

`templates/documents/PROJECT_BRIEF_TEMPLATE.md`

Não altere a ordem das seções.

Não remova nenhuma seção.

Caso alguma informação esteja ausente, preencha com **TODO**.

Ao final do documento, apresente uma seção chamada **Pendências**, contendo todas as informações que ainda precisam ser definidas para que o projeto possa ser implementado sem ambiguidades.

---

# Instrução Final

Utilize obrigatoriamente a estrutura definida em `templates/documents/PROJECT_BRIEF_TEMPLATE.md`.

Não altere a ordem das seções.

Não remova seções.

Caso alguma informação esteja ausente, preencha com **TODO**.

O **PROJECT_BRIEF** deve ser tratado como a única fonte oficial de verdade do projeto.

Evite depender de qualquer informação externa à conversa.

Não crie referências que exijam a leitura do histórico para serem compreendidas.

O documento deve ser completamente autossuficiente.