# Implementation Plan: Migração para Mercado Pago Checkout API

## Overview

Este plano detalha as tarefas de implementação para migrar o sistema de pagamento do aplicativo "Cria" do modelo "Checkout Preferences" para "Checkout API" (Checkout Transparente) do Mercado Pago. A implementação será dividida em backend (Supabase Edge Functions em TypeScript/Deno), frontend (Flutter/Dart), e testes automatizados.

## Tasks

- [ ] 1. Configurar ambiente e variáveis
  - Verificar se MP_ACCESS_TOKEN está configurado no Supabase
  - Configurar SUPABASE_URL e SERVICE_ROLE_KEY para webhooks
  - Documentar estrutura de variáveis de ambiente necessárias
  - _Requirements: 1.4, 12.4_

- [ ] 2. Implementar Edge Function: create-checkout-api
  - [ ] 2.1 Criar arquivo base da Edge Function
    - Criar arquivo `supabase/functions/create-checkout-api/index.ts`
    - Configurar CORS headers e handler básico
    - Implementar tratamento de OPTIONS para CORS preflight
    - _Requirements: 1.1, 1.5, 3.1_

  - [ ] 2.2 Implementar validação de entrada
    - Validar campos obrigatórios (items, giver_name, giver_phone)
    - Validar formato de telefone (10-11 dígitos)
    - Validar array de items não vazio
    - Retornar erros específicos para cada campo inválido
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 2.4_

  - [ ] 2.3 Implementar integração com Mercado Pago Checkout API
    - Calcular valor total dos items
    - Construir payload de pagamento com metadata (family_id, buyer_data, item_ids)
    - Fazer POST para https://api.mercadopago.com/v1/payments
    - Incluir X-Idempotency-Key para prevenir duplicação
    - Configurar notification_url para webhook
    - _Requirements: 1.1, 1.2, 1.3, 4.4_

  - [ ] 2.4 Implementar extração e retorno de dados PIX
    - Extrair qr_code e qr_code_base64 da resposta do MP
    - Retornar payment_id, qr_code, qr_code_base64, expiration_date
    - _Requirements: 1.6, 3.2_

  - [ ] 2.5 Implementar tratamento de erros
    - Tratar erros de validação (400)
    - Tratar erros da API do Mercado Pago (502/503)
    - Implementar logging de erros com sanitização de dados sensíveis
    - Retornar mensagens amigáveis ao usuário
    - _Requirements: 10.1, 10.2, 10.4_

  - [ ]* 2.6 Escrever testes unitários para create-checkout-api
    - Testar validação de campos obrigatórios
    - Testar formato de resposta em sucesso
    - Testar tratamento de erro quando MP API está indisponível
    - Testar cálculo correto do valor total
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [ ]* 2.7 Escrever property test para criação de pagamento
    - **Property 2: Payment Creation Returns PIX Data**
    - **Validates: Requirements 1.2, 1.5, 1.6, 3.1, 3.2**
    - Gerar requests válidos aleatórios e verificar que resposta sempre contém payment_id, qr_code, qr_code_base64

- [ ] 3. Implementar Edge Function: check-payment-status
  - [ ] 3.1 Criar arquivo base da Edge Function
    - Criar arquivo `supabase/functions/check-payment-status/index.ts`
    - Configurar CORS headers e handler GET
    - Extrair payment_id dos query parameters
    - _Requirements: 3.3_

  - [ ] 3.2 Implementar consulta de status no Mercado Pago
    - Validar que payment_id foi fornecido
    - Fazer GET para https://api.mercadopago.com/v1/payments/{payment_id}
    - Retornar status e status_detail
    - Tratar erros de API
    - _Requirements: 3.3, 4.2_

  - [ ]* 3.3 Escrever testes unitários para check-payment-status
    - Testar que payment_id é obrigatório
    - Testar retorno de status correto do MP
    - Testar tratamento de erro quando payment_id inválido

  - [ ]* 3.4 Escrever property test para consulta de status
    - **Property 8: Payment Status Polling Returns Current Status**
    - **Validates: Requirements 3.3**
    - Gerar payment_ids válidos e verificar que endpoint sempre retorna status válido

- [ ] 4. Atualizar Edge Function: mp-webhook
  - [ ] 4.1 Modificar handler para processar Checkout API webhooks
    - Extrair payment_id de body.data.id
    - Filtrar apenas eventos de tipo "payment.*"
    - Implementar logging de eventos recebidos
    - _Requirements: 4.1_

  - [ ] 4.2 Implementar validação de autenticidade do webhook
    - Consultar GET /v1/payments/{payment_id} no MP para validar
    - Verificar se status é "approved" antes de processar
    - Retornar 200 para eventos não-approved (evitar retry desnecessário)
    - _Requirements: 4.2, 12.2, 12.5_

  - [ ] 4.3 Implementar extração de metadata e persistência
    - Extrair metadata (family_id, giver_name, giver_nickname, giver_phone, message_to_parents, item_ids)
    - Fazer split de item_ids por vírgula
    - Inserir gift_contribution para cada item usando upsert com mp_transaction_id
    - Atualizar gift_status='received' para cada item
    - _Requirements: 4.3, 4.4, 4.7, 5.1, 5.2, 5.3, 5.4_

  - [ ] 4.4 Implementar idempotência de webhook
    - Usar mp_transaction_id como chave única (formato: {payment_id}_{item_id})
    - Configurar upsert com onConflict: 'mp_transaction_id'
    - _Requirements: 4.5_

  - [ ] 4.5 Implementar sanitização de entrada
    - Sanitizar todos os campos de metadata antes de inserir no banco
    - Prevenir SQL injection
    - _Requirements: 12.6_

  - [ ]* 4.6 Escrever testes unitários para mp-webhook
    - Testar que eventos não-payment são ignorados
    - Testar que webhook consulta MP API antes de salvar
    - Testar idempotência (múltiplas chamadas = 1 registro)
    - Testar que metadata é extraído corretamente

  - [ ]* 4.7 Escrever property test para webhook idempotency
    - **Property 5: Webhook Idempotency**
    - **Validates: Requirements 4.5**
    - Processar mesmo webhook N vezes e verificar que apenas 1 contribution é criado

  - [ ]* 4.8 Escrever property test para persistência de dados
    - **Property 1: Payment Approval Persists Complete Buyer Data**
    - **Validates: Requirements 4.3, 4.4, 5.1, 5.2, 5.3**
    - Gerar pagamentos aprovados aleatórios e verificar que todos os campos de buyer_data são salvos

  - [ ]* 4.9 Escrever property test para atualização de item status
    - **Property 6: Item Status Update After Payment**
    - **Validates: Requirements 4.7**
    - Verificar que todos os items em item_ids têm gift_status='received' após webhook

- [ ] 5. Checkpoint - Testar Edge Functions no Supabase
  - Deploy das 3 Edge Functions para ambiente de desenvolvimento
  - Testar create-checkout-api com dados válidos via Postman/curl
  - Testar check-payment-status com payment_id real
  - Testar mp-webhook com payload simulado do Mercado Pago
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implementar validações de formulário no Flutter
  - [ ] 6.1 Criar classe CheckoutFormValidator
    - Criar arquivo `lib/validators/checkout_form_validator.dart`
    - Implementar validateName (mínimo 3 caracteres, não vazio)
    - Implementar validatePhone (10-11 dígitos, apenas números)
    - Implementar validateMessage (opcional, máximo 200 caracteres)
    - _Requirements: 2.2, 2.4, 2.5, 11.1, 11.2_

  - [ ]* 6.2 Escrever testes unitários para validadores
    - Testar validateName com strings vazias e válidas
    - Testar validatePhone com formatos válidos e inválidos
    - Testar validateMessage com strings longas

  - [ ]* 6.3 Escrever property test para validação de telefone
    - **Property 3: Phone Number Validation**
    - **Validates: Requirements 2.5, 11.2**
    - Gerar strings aleatórias e verificar que apenas 10-11 dígitos são aceitos

- [ ] 7. Implementar serviço de pagamento no Flutter
  - [ ] 7.1 Criar PaymentService
    - Criar arquivo `lib/services/payment_service.dart`
    - Implementar método createCheckout que chama Edge Function create-checkout-api
    - Implementar método checkPaymentStatus que chama Edge Function check-payment-status
    - Configurar SupabaseClient para fazer requisições
    - _Requirements: 1.5, 3.3_

  - [ ] 7.2 Implementar tratamento de erros e retry
    - Implementar retry automático para erros de rede (máximo 3 tentativas)
    - Parsear erros da API e retornar mensagens amigáveis
    - Implementar timeout de 30 segundos por requisição
    - _Requirements: 10.1, 10.2, 10.3_

  - [ ]* 7.3 Escrever testes unitários para PaymentService
    - Testar createCheckout com mock de Supabase client
    - Testar checkPaymentStatus com diferentes status
    - Testar retry logic em caso de falha de rede

- [ ] 8. Implementar widget PixPaymentScreen
  - [ ] 8.1 Criar estrutura base do widget
    - Criar arquivo `lib/screens/pix_payment_screen.dart`
    - Criar StatefulWidget com parâmetros: paymentId, qrCode, qrCodeBase64, familyId
    - Implementar layout com QR Code, código copiável, e timer
    - _Requirements: 3.2_

  - [ ] 8.2 Implementar exibição de QR Code
    - Adicionar dependência qr_flutter no pubspec.yaml
    - Exibir QR Code usando QrImage widget com qrCodeBase64
    - Exibir código PIX em texto copiável
    - Adicionar botão "Copiar código PIX"
    - _Requirements: 1.2, 3.2_

  - [ ] 8.3 Implementar timer de expiração
    - Exibir countdown de 10 minutos
    - Atualizar UI a cada segundo
    - Redirecionar para tela de timeout quando expirar
    - _Requirements: 3.4_

  - [ ] 8.4 Implementar polling de status de pagamento
    - Criar Timer que chama checkPaymentStatus a cada 3 segundos
    - Cancelar timer quando status = "approved" ou timeout
    - Redirecionar para tela de confirmação quando aprovado
    - _Requirements: 3.3_

  - [ ]* 8.5 Escrever widget tests para PixPaymentScreen
    - Testar que QR Code é exibido
    - Testar que polling inicia automaticamente
    - Testar que timer de expiração funciona

- [ ] 9. Implementar tela de confirmação pós-pagamento
  - [ ] 9.1 Criar ConfirmationScreen widget
    - Criar arquivo `lib/screens/confirmation_screen.dart`
    - Exibir mensagem de sucesso com nome do bebê
    - Adicionar botão "Voltar para lista de presentes"
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ]* 9.2 Escrever widget tests para ConfirmationScreen
    - Testar que mensagem de sucesso é exibida
    - Testar que botão de retorno funciona

- [ ] 10. Atualizar web_gift_screen.dart para usar novo fluxo
  - [ ] 10.1 Modificar formulário de checkout
    - Adicionar campos: giver_name, giver_nickname, giver_phone, message_to_parents
    - Aplicar validadores do CheckoutFormValidator
    - Exibir mensagens de erro específicas para cada campo
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ] 10.2 Modificar handler de submit do formulário
    - Remover redirecionamento para Mercado Pago externo
    - Chamar PaymentService.createCheckout com dados do formulário
    - Navegar para PixPaymentScreen com dados retornados
    - Tratar erros e exibir mensagens amigáveis
    - _Requirements: 1.6, 3.1, 10.1, 10.2_

  - [ ]* 10.3 Escrever widget tests para formulário atualizado
    - Testar validação de campos
    - Testar submit com dados válidos
    - Testar exibição de erros

- [ ] 11. Verificar compatibilidade com Gift Wall existente
  - [ ] 11.1 Testar exibição de contribuições no Gift Wall
    - Verificar que gift_contributions são exibidos corretamente
    - Verificar que giver_name, giver_nickname, message_to_parents aparecem
    - Verificar que botão "Agradecer no WhatsApp" funciona
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

  - [ ] 11.2 Implementar geração de URL do WhatsApp
    - Verificar que wa.me/{phone} é gerado corretamente
    - Verificar que mensagem pré-preenchida usa formato correto
    - Tratar casos onde giver_phone está ausente
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ]* 11.3 Escrever property test para formato de URL do WhatsApp
    - **Property 12: WhatsApp URL Format**
    - **Validates: Requirements 8.4**
    - Gerar telefones válidos e verificar que URL sempre tem formato correto

  - [ ]* 11.4 Escrever property test para mensagem do WhatsApp
    - **Property 13: WhatsApp Message Format**
    - **Validates: Requirements 8.3**
    - Verificar que mensagem sempre segue formato "Oi {nickname}, muito obrigado pelo presente! 💛"

- [ ] 12. Checkpoint - Testar fluxo completo end-to-end
  - Testar fluxo completo: formulário → pagamento → webhook → Gift Wall
  - Usar sandbox do Mercado Pago para simular pagamento PIX
  - Verificar que contribution aparece no Gift Wall após pagamento
  - Verificar que item_status é atualizado para "received"
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Implementar testes de integração
  - [ ]* 13.1 Escrever teste end-to-end completo
    - Testar fluxo: create-checkout-api → check-payment-status → mp-webhook → database
    - Verificar que contribution é salvo corretamente
    - Verificar que item status é atualizado
    - _Requirements: 4.3, 4.7, 5.1, 7.1_

  - [ ]* 13.2 Escrever property tests adicionais
    - **Property 4: Webhook Validates Payment Before Persistence**
    - **Validates: Requirements 4.2, 12.2, 12.5**
    - **Property 7: Default Thanked Flag**
    - **Validates: Requirements 5.4**
    - **Property 10: Required Field Validation**
    - **Validates: Requirements 2.2, 2.4, 11.1, 11.3, 11.4**
    - **Property 11: Error Response Structure**
    - **Validates: Requirements 3.5, 10.1, 10.2**
    - **Property 14: Input Sanitization**
    - **Validates: Requirements 12.6**
    - **Property 15: Saved Contributions Are Queryable**
    - **Validates: Requirements 7.1**

- [ ] 14. Configurar webhook URL no Mercado Pago
  - Acessar painel do Mercado Pago
  - Configurar notification_url: {SUPABASE_URL}/functions/v1/mp-webhook
  - Testar webhook com ferramenta de teste do MP
  - Verificar logs no Supabase para confirmar recebimento
  - _Requirements: 4.1_

- [ ] 15. Testes de segurança e validação final
  - [ ] 15.1 Verificar sanitização de inputs
    - Testar inputs com caracteres especiais SQL
    - Verificar que dados sensíveis não são logados
    - Verificar que tokens são mascarados em logs
    - _Requirements: 12.6_

  - [ ] 15.2 Verificar uso de HTTPS
    - Confirmar que todas as chamadas de API usam HTTPS
    - Verificar certificados SSL
    - _Requirements: 12.1_

  - [ ] 15.3 Verificar proteção de credenciais
    - Confirmar que MP_ACCESS_TOKEN está em variável de ambiente
    - Verificar que SERVICE_ROLE_KEY não está exposto no frontend
    - _Requirements: 12.4_

- [ ] 16. Documentação e deploy
  - [ ] 16.1 Documentar fluxo de pagamento
    - Criar diagrama de sequência atualizado
    - Documentar variáveis de ambiente necessárias
    - Documentar processo de configuração do webhook
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ] 16.2 Deploy para ambiente de staging
    - Deploy das Edge Functions para Supabase staging
    - Configurar variáveis de ambiente de staging
    - Testar com credenciais de sandbox do Mercado Pago

  - [ ] 16.3 Criar plano de rollback
    - Documentar como reverter para Checkout Preferences se necessário
    - Manter Edge Functions antigas como backup
    - Documentar processo de rollback de banco de dados

- [ ] 17. Final checkpoint - Validação completa
  - Executar todos os testes automatizados (unit + property + integration)
  - Verificar cobertura de testes (mínimo 80%)
  - Testar fluxo completo em staging com pagamento real
  - Validar que nenhuma funcionalidade existente foi quebrada
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- Cada task referencia requirements específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Property tests validam propriedades universais de corretude
- Unit tests validam exemplos específicos e casos extremos
- Testes de integração validam fluxo end-to-end completo
- Priorizar implementação de backend antes de frontend para facilitar testes
- Usar sandbox do Mercado Pago durante todo o desenvolvimento
- Manter compatibilidade total com banco de dados existente (sem alterações de schema)
