import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

serve(async (req) => {
  try {
    const body = await req.json();

    // Extrai payment_id da notificação
    const paymentId = body.data?.id;
    const action = body.action;

    console.log(`[Webhook] Received: action=${action}, paymentId=${paymentId}`);

    // Ignora eventos que não são de pagamento
    if (!paymentId || !action?.startsWith("payment.")) {
      console.log("[Webhook] Ignoring non-payment event");
      return new Response("OK", { status: 200 });
    }

    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY");

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SERVICE_ROLE_KEY) {
      throw new Error("Missing environment variables");
    }

    // Valida autenticidade consultando API do Mercado Pago (Segurança)
    const mpResponse = await fetch(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: { "Authorization": `Bearer ${MP_ACCESS_TOKEN}` },
      },
    );

    if (!mpResponse.ok) {
      throw new Error(`Failed to validate payment ${paymentId}`);
    }

    const paymentData = await mpResponse.json();
    console.log(`[Webhook] Payment status: ${paymentData.status}`);

    // Só processa se pagamento foi aprovado
    if (paymentData.status !== "approved") {
      console.log("[Webhook] Payment not approved yet, skipping persistence");
      return new Response(
        JSON.stringify({
          received: true,
          status: paymentData.status,
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 200,
        },
      );
    }

    // Extrai metadata
    const metadata = paymentData.metadata;
    if (!metadata || !metadata.family_id) {
      console.error("[Webhook] Missing metadata in payment");
      return new Response("Missing metadata", { status: 400 });
    }

    // Conecta no Supabase ignorando RLS (usando Service Role Key)
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const itemIds = metadata.item_ids ? metadata.item_ids.split(",") : [];

    // Insere contribuições no banco (uma por item)
    for (const itemId of itemIds) {
      const transactionKey = `${paymentId}_${itemId}`;

      const { error: insertError } = await supabase
        .from("gift_contributions")
        .upsert({
          mp_transaction_id: transactionKey,
          family_id: metadata.family_id,
          item_id: itemId,
          giver_name: metadata.giver_name || "",
          giver_nickname: metadata.giver_nickname || "",
          giver_phone: metadata.giver_phone || "",
          message_to_parents: metadata.message_to_parents || "",
          thanked: false,
        }, {
          onConflict: "mp_transaction_id", // Previne duplicatas se o MP chamar o webhook duas vezes
        });

      if (insertError) {
        console.error(
          `[Webhook] Error inserting contribution ${transactionKey}:`,
          insertError,
        );
      } else {
        console.log(`[Webhook] Contribution recorded: ${transactionKey}`);
      }

      // Atualiza status do item para "received"
      const { error: updateError } = await supabase
        .from("items")
        .update({ gift_status: "received" })
        .eq("id", itemId);

      if (updateError) {
        console.error(`[Webhook] Error updating item ${itemId}:`, updateError);
      } else {
        console.log(`[Webhook] Item ${itemId} marked as received`);
      }
    }

    return new Response(
      JSON.stringify({
        received: true,
        status: "approved",
        processed: true,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error: any) {
    console.error("[Webhook] Error:", error.message);
    return new Response(error.message, { status: 500 });
  }
});
