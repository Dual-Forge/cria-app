-- Adiciona o ID da transação do Mercado Pago
ALTER TABLE gift_contributions ADD COLUMN IF NOT EXISTS mp_transaction_id TEXT UNIQUE;

-- Garante que a coluna giver_phone exista (se já existe o IF NOT EXISTS ignora)
ALTER TABLE gift_contributions ADD COLUMN IF NOT EXISTS giver_phone TEXT;
