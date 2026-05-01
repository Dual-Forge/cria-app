-- Adicionar coluna media_type à tabela baby_timeline
ALTER TABLE baby_timeline
ADD COLUMN media_type VARCHAR(10) NOT NULL DEFAULT 'image';

-- Permitir arquivos mp4/mov no bucket (configuração do storage, ajustamos policy se necessário)
-- Update the allowed mime types in storage settings if needed via Supabase Dashboard
