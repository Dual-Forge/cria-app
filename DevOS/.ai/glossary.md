# Glossário do Projeto Cria

- **BPM**: Batimentos Por Minuto, a métrica clínica usada para monitorar a frequência cardíaca do bebê (limites aceitos: 40 a 200).
- **Edge Function**: Funções computacionais "serverless" do Supabase escritas em Deno. Usadas aqui para isolar chaves de pagamentos e receber Webhooks do Mercado Pago sem comprometer o frontend.
- **Mercado Pago (MP)**: A plataforma de pagamentos parceira utilizada para gerar a cobrança Pix (Checkout API).
- **RLS (Row Level Security)**: Recurso do PostgreSQL do Supabase usado ativamente neste projeto para que famílias só tenham acesso aos registros do banco associados ao seu próprio `family_id`.
- **Gemini / LLM**: A inteligência artificial acionada (Google Gemini via Python) que recebe a tarefa não estruturada de "digerir o HTML de qualquer loja online e convertê-lo em um pacote JSON com preço e nome da fralda/produto".
- **GoRouter**: A biblioteca no Flutter responsável por gerenciar navegação e Deep Links, fundamental para a renderização pública na Web das vitrines de presente (`/presentes/:id`).