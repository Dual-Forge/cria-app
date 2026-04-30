# PLAN: Payment Flow Fix - PIX, Credit & Debit Cards

**Project Type:** WEB (Flutter Web + Supabase Edge Functions)  
**Status:** 🔴 CRITICAL BUG - 400 Bad Request on Payment Creation  
**Goal:** Fix payment flow for PIX, credit card, and debit card payments

---

## 🎯 Executive Summary

**Problem:** Intermittent 400 errors (`payer_cannot_be_nil`) when creating payments via Mercado Pago API.

**Root Cause Identified:**
- ✅ Typo in `payment_service.dart` line 29: `'giver_Email'` → `'giver_email'` (FIXED)
- ⚠️ Potential additional issues in payload validation and Mercado Pago API contract

**Scope:** 
- Fix PIX payment flow (immediate priority)
- Extend to credit/debit card support (phase 2)
- Implement comprehensive error handling and logging

---

## 📋 Phase Breakdown

### Phase 0: Pre-Flight Verification ✅
**Status:** COMPLETED
- [x] Spec exists: `.kiro/specs/mercadopago-checkout-api-migration/`
- [x] Project type: WEB
- [x] Critical typo fixed: `giver_Email` → `giver_email`

### Phase 1: Payload Contract Audit 🔍
**Owner:** `debugger` + `backend-specialist`  
**Duration:** 30 min  
**Priority:** 🔴 CRITICAL
**Status:** ✅ COMPLETED

**Tasks:**
1. **Verify Frontend → Edge Function Contract** ✅ DONE
   - ✅ Fixed typo: `'giver_Email'` → `'giver_email'` in `payment_service.dart` line 29
   - ✅ Verified camelCase (Dart) → snake_case (API) conversion
   - ✅ Confirmed all required fields: `items`, `family_id`, `giver_name`, `giver_phone`, `giver_email`

2. **Verify Edge Function → Mercado Pago Contract** ✅ DONE
   - ✅ Used MCP Mercado Pago to validate `payer` object schema
   - ✅ Confirmed required fields: `email`, `first_name`, `last_name`
   - ✅ Validated `transaction_amount` is `number` (not string) - FIXED
   - ✅ Verified `payment_method_id` values: `"pix"`, `"credit_card"`, `"debit_card"`

3. **Add Detailed Logging** ✅ DONE
   - ✅ Added `console.log("Body recebido:", JSON.stringify(body))` at Edge Function entry
   - ✅ Log sanitized payload before Mercado Pago API call
   - ✅ Log full MP API response (success and error cases)

**Deliverables:**
- [x] Contract validation report → `docs/AUDIT-REPORT-payment-flow.md`
- [x] Enhanced logging in `create-checkout-api/index.ts`
- [x] Fixed critical typo in `payment_service.dart`
- [x] Guaranteed `transaction_amount` as `number` type

---

### Phase 2: PIX Payment Flow Validation 💳
**Owner:** `backend-specialist` + `test-engineer`  
**Duration:** 1 hour  
**Priority:** 🔴 CRITICAL

**Tasks:**
1. **Validate PIX-Specific Requirements**
   - Confirm `payment_method_id: "pix"` is correct
   - Verify `point_of_interaction.transaction_data` extraction
   - Check QR code generation: `qr_code`, `qr_code_base64`
   - Validate expiration date handling

2. **Test PIX Flow End-to-End**
   - Create test case with valid guest data
   - Verify QR code is generated
   - Confirm payment status polling works
   - Test webhook notification handling

3. **Error Handling for PIX**
   - Handle 503 (service unavailable) with retry logic
   - Handle 400 (bad request) with detailed error messages
   - Implement exponential backoff (already exists, verify)

**Deliverables:**
- [ ] PIX flow test suite
- [ ] Error handling validation
- [ ] QR code generation test

---

### Phase 3: Credit/Debit Card Support 💳
**Owner:** `backend-specialist` + `security-auditor`  
**Duration:** 2 hours  
**Priority:** 🟡 HIGH

**Tasks:**
1. **Extend Edge Function for Card Payments**
   - Add card tokenization support (Mercado Pago SDK)
   - Implement `payment_method_id: "credit_card"` / `"debit_card"`
   - Add installments support for credit cards
   - Validate CVV, expiration date, card number

2. **Frontend Card Input Form**
   - Create `CardPaymentScreen` widget
   - Add card number input with masking
   - Add CVV and expiration date fields
   - Implement card brand detection (Visa, Mastercard, etc.)

3. **Security Validation**
   - Ensure card data is NEVER logged
   - Verify PCI-DSS compliance (tokenization only)
   - Implement 3DS authentication if required
   - Add rate limiting for card attempts

**Deliverables:**
- [ ] Card payment Edge Function
- [ ] Card input UI component
- [ ] Security audit report

---

### Phase 4: Idempotency & Retry Logic 🔄
**Owner:** `backend-specialist`  
**Duration:** 30 min  
**Priority:** 🟡 HIGH

**Tasks:**
1. **Verify Idempotency Key Generation**
   - Confirm `crypto.randomUUID()` is unique per request
   - Check if retry logic regenerates key (should NOT)
   - Implement idempotency key storage for retries

2. **Enhance Retry Logic**
   - Current: 3 retries with exponential backoff (2s, 4s, 6s)
   - Add: Preserve idempotency key across retries
   - Add: Distinguish between retryable (503) and non-retryable (400) errors

**Deliverables:**
- [ ] Idempotency key validation
- [ ] Enhanced retry logic

---

### Phase 5: Webhook Integration 🔔
**Owner:** `backend-specialist` + `database-architect`  
**Duration:** 1 hour  
**Priority:** 🟡 HIGH

**Tasks:**
1. **Verify Webhook Configuration**
   - Confirm `notification_url` points to `mp-webhook` function
   - Test webhook signature validation
   - Verify payment status updates in database

2. **Handle Payment Events**
   - `payment.created` → Update status to "pending"
   - `payment.approved` → Update status to "approved", trigger Gift Wall update
   - `payment.rejected` → Update status to "rejected", notify user

3. **Database Updates**
   - Create `payments` table if not exists
   - Store: `payment_id`, `status`, `amount`, `method`, `giver_info`, `metadata`
   - Link payment to `gifts` table

**Deliverables:**
- [ ] Webhook handler validation
- [ ] Database schema for payments
- [ ] Payment status update flow

---

### Phase 6: Testing & Validation ✅
**Owner:** `test-engineer` + `qa-automation-engineer`  
**Duration:** 2 hours  
**Priority:** 🟢 MEDIUM

**Tasks:**
1. **Unit Tests**
   - `payment_service_test.dart`: Test all payment methods
   - `create-checkout-api/index.test.ts`: Test Edge Function logic
   - `mp-webhook/index.test.ts`: Test webhook handling

2. **Integration Tests**
   - End-to-end PIX flow
   - End-to-end card payment flow
   - Webhook notification flow

3. **Error Scenario Tests**
   - Invalid email format
   - Missing required fields
   - Mercado Pago API errors (400, 503)
   - Network timeout scenarios

**Deliverables:**
- [ ] Unit test suite (80%+ coverage)
- [ ] Integration test suite
- [ ] Error scenario test suite

---

### Phase 7: Deployment & Monitoring 🚀
**Owner:** `devops-engineer`  
**Duration:** 30 min  
**Priority:** 🟢 MEDIUM

**Tasks:**
1. **Deploy Edge Functions**
   ```bash
   cd supabase
   supabase functions deploy create-checkout-api
   supabase functions deploy check-payment-status
   supabase functions deploy mp-webhook
   ```

2. **Deploy Flutter Web**
   ```bash
   cd cria_app
   flutter build web --release
   vercel deploy --prod
   ```

3. **Configure Environment Variables**
   - Verify `MP_ACCESS_TOKEN` is TEST token in Supabase Secrets
   - Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Flutter
   - Add `MP_PUBLIC_KEY` for frontend card tokenization

4. **Setup Monitoring**
   - Enable Supabase Function logs
   - Setup error alerting (Sentry/LogRocket)
   - Monitor payment success rate

**Deliverables:**
- [ ] Deployment commands
- [ ] Environment variable checklist
- [ ] Monitoring dashboard

---

## 🔧 Technical Stack

| Layer | Technology | Files |
|-------|-----------|-------|
| **Frontend** | Flutter Web | `web_gift_screen.dart`, `pix_payment_screen.dart` |
| **Service** | Dart | `payment_service.dart` |
| **Backend** | Supabase Edge Functions (Deno) | `create-checkout-api/index.ts` |
| **Payment** | Mercado Pago API | PIX, Credit, Debit |
| **Webhook** | Supabase Function | `mp-webhook/index.ts` |
| **Database** | Supabase (PostgreSQL) | `payments`, `gifts` tables |

---

## 🎯 Success Criteria

| Metric | Target | Current |
|--------|--------|---------|
| **PIX Success Rate** | >95% | ~60% (400 errors) |
| **Card Success Rate** | >90% | Not implemented |
| **Error Handling** | All errors logged & user-friendly | Partial |
| **Test Coverage** | >80% | ~40% |
| **Webhook Reliability** | 100% | Unknown |

---

## 🚨 Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Mercado Pago API Changes** | 🔴 HIGH | Use MCP for schema validation |
| **Card Tokenization Complexity** | 🟡 MEDIUM | Use official Mercado Pago SDK |
| **Webhook Signature Validation** | 🟡 MEDIUM | Implement HMAC verification |
| **PCI-DSS Compliance** | 🔴 HIGH | Never store card data, use tokens only |

---

## 📦 Deliverables Summary

### Immediate (Phase 1-2)
- [x] Fix `giver_Email` typo (DONE)
- [ ] Enhanced logging in Edge Function
- [ ] PIX flow validation
- [ ] Contract audit report

### Short-term (Phase 3-4)
- [ ] Credit/debit card support
- [ ] Idempotency validation
- [ ] Security audit

### Medium-term (Phase 5-7)
- [ ] Webhook integration
- [ ] Comprehensive test suite
- [ ] Production deployment

---

## 🔄 Next Steps

1. **Review this plan** with stakeholders
2. **Execute Phase 1** (Payload Contract Audit)
3. **Execute Phase 2** (PIX Flow Validation)
4. **Deploy fixes** to staging environment
5. **Test end-to-end** with real Mercado Pago TEST credentials
6. **Deploy to production** after validation

---

## 📞 Agent Assignments

| Phase | Primary Agent | Support Agent |
|-------|--------------|---------------|
| Phase 1 | `debugger` | `backend-specialist` |
| Phase 2 | `backend-specialist` | `test-engineer` |
| Phase 3 | `backend-specialist` | `security-auditor` |
| Phase 4 | `backend-specialist` | - |
| Phase 5 | `backend-specialist` | `database-architect` |
| Phase 6 | `test-engineer` | `qa-automation-engineer` |
| Phase 7 | `devops-engineer` | - |

---

**Plan Created:** 2026-03-19  
**Last Updated:** 2026-03-19  
**Status:** 🟡 READY FOR EXECUTION
