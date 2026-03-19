# Requirements Document

## Introduction

Este documento especifica os requisitos para a migração do sistema de pagamento do aplicativo "Cria" (lista de presentes de bebê) do modelo "Checkout Preferences" para "Checkout API" (Checkout Transparente) do Mercado Pago. O objetivo principal é resolver o bug do PIX mantendo todas as funcionalidades existentes da página "Mural de Presentes" e garantindo compatibilidade total com o banco de dados Supabase existente.

## Glossary

- **Checkout_API**: Sistema de pagamento transparente do Mercado Pago que processa pagamentos sem redirecionar para site externo
- **Checkout_Preferences**: Sistema legado do Mercado Pago que redireciona para página externa de pagamento
- **Guest_Checkout**: Fluxo de compra que não exige criação de conta ou login do comprador
- **Payment_System**: Componente responsável por processar pagamentos via Mercado Pago
- **Webhook_Handler**: Edge Function que recebe notificações de pagamento do Mercado Pago
- **Gift_Wall**: Mural de presentes onde os pais visualizam contribuições recebidas
- **Buyer_Data**: Dados do comprador (nome, apelido, WhatsApp, mensagem)
- **Gift_Contribution**: Registro de presente comprado no banco de dados
- **Edge_Function**: Função serverless executada no Supabase
- **MCP_Server**: Servidor MCP do Mercado Pago já instalado e configurado
- **PIX_Payment**: Método de pagamento instantâneo brasileiro prioritário no sistema

## Requirements

### Requirement 1: Implementar Checkout API do Mercado Pago

**User Story:** Como desenvolvedor, eu quero migrar do Checkout Preferences para Checkout API, para que o bug do PIX seja resolvido e os pagamentos funcionem corretamente.

#### Acceptance Criteria

1. THE Payment_System SHALL use Checkout API instead of Checkout Preferences
2. THE Payment_System SHALL support PIX_Payment as the primary payment method
3. THE Payment_System SHALL use the existing MCP_Server for API integration
4. THE Payment_System SHALL maintain compatibility with existing production credentials
5. WHEN a payment is initiated, THE Payment_System SHALL create a payment order via Checkout API
6. THE Payment_System SHALL NOT redirect users to external Mercado Pago pages

### Requirement 2: Manter Fluxo Guest Checkout

**User Story:** Como comprador visitante, eu quero presentear sem criar conta, para que o processo seja rápido e sem fricção.

#### Acceptance Criteria

1. THE Guest_Checkout SHALL collect Buyer_Data directly on the gift page
2. THE Guest_Checkout SHALL require: buyer name, nickname, WhatsApp number, and message to baby
3. THE Guest_Checkout SHALL NOT require account creation or login
4. WHEN Buyer_Data is incomplete, THE Guest_Checkout SHALL display validation errors
5. THE Guest_Checkout SHALL validate WhatsApp number format before submission

### Requirement 3: Processar Pagamentos Transparentemente

**User Story:** Como comprador, eu quero pagar diretamente no site, para que não precise sair da página de presentes.

#### Acceptance Criteria

1. WHEN a buyer submits payment, THE Payment_System SHALL process it without external redirects
2. THE Payment_System SHALL display PIX QR code and payment instructions on the same page
3. WHEN payment is pending, THE Payment_System SHALL show real-time status updates
4. THE Payment_System SHALL support payment via PIX with maximum 10-minute expiration
5. IF payment fails, THEN THE Payment_System SHALL display clear error messages and retry options

### Requirement 4: Implementar Webhook para Notificações de Pagamento

**User Story:** Como sistema, eu quero receber notificações de pagamento aprovado, para que os dados sejam salvos automaticamente no banco.

#### Acceptance Criteria

1. THE Webhook_Handler SHALL receive payment notifications from Mercado Pago
2. WHEN a payment notification is received, THE Webhook_Handler SHALL validate the payment status via Mercado Pago API
3. WHEN payment status is "approved", THE Webhook_Handler SHALL save Gift_Contribution to database
4. THE Webhook_Handler SHALL extract Buyer_Data from payment metadata
5. THE Webhook_Handler SHALL handle duplicate webhook calls using mp_transaction_id as unique key
6. IF webhook validation fails, THEN THE Webhook_Handler SHALL log the error and return appropriate HTTP status
7. THE Webhook_Handler SHALL update gift item status to "received" after successful payment

### Requirement 5: Salvar Dados do Comprador no Banco

**User Story:** Como sistema, eu quero salvar os dados do comprador após pagamento aprovado, para que os pais possam agradecer posteriormente.

#### Acceptance Criteria

1. WHEN payment is approved, THE Webhook_Handler SHALL insert Gift_Contribution record with Buyer_Data
2. THE Gift_Contribution SHALL include: family_id, item_id, giver_name, giver_nickname, giver_phone, message_to_parents
3. THE Webhook_Handler SHALL link WhatsApp number to the Gift_Contribution record
4. THE Webhook_Handler SHALL set thanked flag to false by default
5. THE Webhook_Handler SHALL maintain compatibility with existing gift_contributions table schema
6. THE Webhook_Handler SHALL NOT modify existing database structure or constraints

### Requirement 6: Exibir Tela de Confirmação Pós-Pagamento

**User Story:** Como comprador, eu quero ver uma confirmação após pagamento bem-sucedido, para que eu saiba que meu presente foi registrado.

#### Acceptance Criteria

1. WHEN payment is confirmed, THE Payment_System SHALL redirect to "Thank You" confirmation screen
2. THE confirmation screen SHALL display a success message with baby name
3. THE confirmation screen SHALL include a button to return to Gift_Wall
4. THE confirmation screen SHALL NOT display sensitive payment information
5. WHEN payment is pending, THE Payment_System SHALL display pending status with instructions

### Requirement 7: Popular Mural de Presentes Automaticamente

**User Story:** Como pais, eu quero ver automaticamente quem deu presentes, para que eu possa agradecer cada pessoa.

#### Acceptance Criteria

1. WHEN a Gift_Contribution is saved, THE Gift_Wall SHALL display it automatically
2. THE Gift_Wall SHALL show: giver name, nickname, message, and gift item
3. THE Gift_Wall SHALL display WhatsApp number linked to "Thank on WhatsApp" button
4. THE Gift_Wall SHALL maintain existing visual design and layout
5. THE Gift_Wall SHALL NOT break existing functionality or data display

### Requirement 8: Implementar Botão de Agradecimento via WhatsApp

**User Story:** Como pais, eu quero agradecer diretamente no WhatsApp, para que eu possa enviar mensagem personalizada para cada presenteador.

#### Acceptance Criteria

1. THE Gift_Wall SHALL display "Thank on WhatsApp" button for each Gift_Contribution
2. WHEN button is clicked, THE Gift_Wall SHALL open WhatsApp with pre-filled message
3. THE WhatsApp message SHALL use format: "Oi {nickname}, muito obrigado pelo presente! 💛"
4. THE Gift_Wall SHALL use wa.me/{phone_number} URL format
5. THE Gift_Wall SHALL handle missing WhatsApp numbers gracefully by disabling the button

### Requirement 9: Manter Compatibilidade com Sistema Existente

**User Story:** Como desenvolvedor, eu quero garantir compatibilidade total, para que nenhuma funcionalidade existente seja quebrada.

#### Acceptance Criteria

1. THE Payment_System SHALL NOT modify existing database schema
2. THE Payment_System SHALL NOT alter existing Supabase Edge Functions unrelated to payment
3. THE Payment_System SHALL maintain compatibility with existing gift_contributions table
4. THE Payment_System SHALL NOT change existing RLS policies on database tables
5. THE Payment_System SHALL preserve all existing Gift_Wall features and UI components
6. THE Payment_System SHALL NOT break existing routes or API contracts

### Requirement 10: Tratar Erros de Pagamento Adequadamente

**User Story:** Como comprador, eu quero ver mensagens claras quando algo der errado, para que eu saiba como proceder.

#### Acceptance Criteria

1. WHEN Mercado Pago API is unavailable, THE Payment_System SHALL display user-friendly error message
2. WHEN payment is rejected, THE Payment_System SHALL explain the reason and offer retry option
3. WHEN network error occurs, THE Payment_System SHALL allow user to retry payment
4. THE Payment_System SHALL log all payment errors for debugging purposes
5. IF payment timeout occurs, THEN THE Payment_System SHALL notify user and provide support contact

### Requirement 11: Validar Dados de Entrada do Comprador

**User Story:** Como sistema, eu quero validar dados do comprador, para que apenas informações válidas sejam processadas.

#### Acceptance Criteria

1. THE Guest_Checkout SHALL validate that buyer name is not empty
2. THE Guest_Checkout SHALL validate WhatsApp number contains only digits and has 10-11 digits
3. THE Guest_Checkout SHALL validate that at least one gift item is selected
4. WHEN validation fails, THE Guest_Checkout SHALL display specific error messages for each field
5. THE Guest_Checkout SHALL prevent form submission until all required fields are valid

### Requirement 12: Garantir Segurança nas Transações

**User Story:** Como desenvolvedor, eu quero garantir segurança nas transações, para que dados sensíveis sejam protegidos.

#### Acceptance Criteria

1. THE Payment_System SHALL use HTTPS for all API communications
2. THE Webhook_Handler SHALL validate webhook authenticity using Mercado Pago signature
3. THE Payment_System SHALL NOT store credit card information
4. THE Payment_System SHALL use environment variables for API credentials
5. THE Webhook_Handler SHALL verify payment status with Mercado Pago API before saving data
6. THE Payment_System SHALL sanitize all user inputs before database insertion
