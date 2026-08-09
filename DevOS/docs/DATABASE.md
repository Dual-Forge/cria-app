# DATABASE

## Objetivo

Este documento descreve a estrutura lógica do banco de dados do Cria.

---

# Banco de Dados

- **Tecnologia**: PostgreSQL (Supabase)
- **Estratégia de Migrations**: Gerenciamento nativo de migrations do Supabase (pasta `supabase/migrations/`).
- **Convenções utilizadas**: `snake_case`, PK `UUID`, `created_at`.

---

# Entidades

## families

### Objetivo
Agrupar usuários autenticados (pais) e informações centralizadas como recebimento financeiro.

### Campos Relevantes
- `id` (UUID, PK)
- `pix_key` (TEXT)

## baby_profile

### Objetivo
Dados gestacionais e monitoramento.

### Campos Relevantes
- `id` (UUID, PK)
- `family_id` (UUID, FK families)
- `profile_photo_url` (TEXT)
- `last_bpm` (INTEGER, CHECK 40-200)
- `kick_count` (INTEGER)
- `expected_due_date` (DATE)

### Restrições
- `UNIQUE(family_id)`: Um perfil de bebê por família.

## items

### Objetivo
Registro de produtos e possíveis presentes.

### Campos Relevantes
- `id` (UUID, PK)
- `is_gift` (BOOLEAN)
- `gift_status` (TEXT, IN: 'available', 'reserved', 'received')

## gift_contributions

### Objetivo
Registrar transações financeiras de contribuições para presentes.

### Campos Relevantes
- `id` (UUID, PK)
- `family_id` (UUID, FK families)
- `item_id` (UUID, FK items)
- `giver_name` (TEXT)
- `giver_nickname` (TEXT)
- `message_to_parents` (TEXT)
- `thanked` (BOOLEAN)

---

# Regras de Integridade e Estratégias

- **Cascade**: Exclusão da família reflete em exclusão em `baby_profile` e `gift_contributions`.
- **Versionamento de timestamp**: Triggers do PostgreSQL operam o update em `updated_at` automaticamente (ex: `update_baby_profile_updated_at()`).
- **Segurança (RLS)**: Row Level Security habilitado ativamente em todas as tabelas. Pais interagem com registros limitados ao seu sub-conjunto `family_id`. Público tem permissão limitada para INSERT na tabela de contribuições e leitura de itens marcados com `is_gift`.
