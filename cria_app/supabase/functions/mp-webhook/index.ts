import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

serve(async (req) => {
  try {
    // 1. Receber Payload do Webhook
    const url = new URL(req.url);
    
    let body = {};
    try {
      if (req.headers.get("content-type")?.includes("application/json")) {
        body = await req.json();
      }
    } catch (e) {
      console.log("[Webhook] Body parsing safely skipped", e.message);
    }

    // Verificamos se é um evento de pagamento
    const topic = url.searchParams.get("topic") || body.type;
    const paymentId = url.searchParams.get("id") || body.data?.id;

    console.log(`[Webhook] Received event: bodyAction=${body.action}, topic=${topic}, paymentId=${paymentId}`);

    if (!paymentId || (topic !== "payment" && body.action !== "payment.updated" && body.action !== "payment.created")) {
      console.log(`[Webhook] Ignoring event: Not a payment created/updated. Topic: ${topic}, Action: ${body.action}`);
      return new Response("Not a payment event", { status: 200 }); // Ignora outros eventos (200 okay pro MP parar de enviar)
    }

    const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN');
    if (!MP_ACCESS_TOKEN) throw new Error('MP_ACCESS_TOKEN missing');

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SERVICE_ROLE_KEY = Deno.env.get('SERVICE_ROLE_KEY');
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) throw new Error('Supabase envs missing');

    // 2. Consultar a API do Mercado Pago para conferir a veracidade e status
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${MP_ACCESS_TOKEN}` }
    });

    if (!mpResponse.ok) {
      throw new Error(`Failed to fetch payment ${paymentId}`);
    }

    const paymentData = await mpResponse.json();

    console.log(`[Webhook] Payment ${paymentId} status: ${paymentData.status}`);

    // 3. Se estiver Aprovado, persista os dados no Supabase
    if (paymentData.status !== "approved") {
      console.log(`[Webhook] Payment ${paymentId} is not approved yet. Ignoring data persistence.`);
      return new Response(JSON.stringify({ received: true, status: paymentData.status }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      });
    }

    const metadata = paymentData.metadata;
    console.log(`[Webhook] Payment metadata:`, JSON.stringify(metadata));

    if (metadata && metadata.family_id) {
      const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

      const itemIds = metadata.item_ids ? metadata.item_ids.split(",") : [];

      for (const itemId of itemIds) {
        // Usamos o paymentId + itemId para garantir unicidade na restrição mp_transaction_id
        const transactionKey = `${paymentId}_${itemId}`;

        const { error } = await supabase.from('gift_contributions').upsert({
          mp_transaction_id: transactionKey,
          family_id: metadata.family_id,
          item_id: itemId,
          giver_name: metadata.giver_name || '',
          giver_nickname: metadata.giver_nickname || '',
          giver_phone: metadata.giver_phone || '',
          message_to_parents: metadata.message_to_parents || '',
          thanked: false,
          // created_at é default NOW()
        }, { onConflict: 'mp_transaction_id' }); // Ignora duplicatas se o Webhook der trigger 2x

        if (error) {
          console.error(`Error inserting contribution ${transactionKey}:`, error);
        } else {
          console.log(`Successfully recorded contribution for ${transactionKey}`);
        }
      }
    }

    return new Response(JSON.stringify({ received: true, status: "approved", processed: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Webhook Error:", (error as Error).message);
    return new Response((error as Error).message, { status: 400 });
  }
});
