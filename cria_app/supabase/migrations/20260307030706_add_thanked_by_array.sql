-- Adiciona um array de UUIDs para registrar os pais que já agradeceram
ALTER TABLE gift_contributions ADD COLUMN IF NOT EXISTS thanked_by UUID[] DEFAULT '{}'::UUID[];
