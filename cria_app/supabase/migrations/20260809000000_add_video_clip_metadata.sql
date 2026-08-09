-- Adicionar metadados de recorte de vídeo à tabela baby_timeline.
-- Permite o "corte suave": o arquivo original fica no storage e apenas o
-- intervalo (start_ms → end_ms, máx 60s) é gravado e reproduzido.
-- Colunas NULL para eventos de imagem e vídeos antigos (reprodução completa).
ALTER TABLE baby_timeline
  ADD COLUMN IF NOT EXISTS video_start_ms BIGINT,
  ADD COLUMN IF NOT EXISTS video_end_ms BIGINT;

-- Backfill: vídeos já existentes reproduzem o arquivo inteiro.
UPDATE baby_timeline
SET
  video_start_ms = NULL,
  video_end_ms   = NULL
WHERE media_type = 'video';