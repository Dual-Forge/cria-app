import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Tratamento de OPTIONS para CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const {
      items,
      family_id,
      giver_name,
      giver_nickname,
      giver_phone,
      message_to_parents,
    } = body;

    // --- TASK 2.2: VALIDAÇÃO DE ENTRADA DETALHADA ---
    const validationErrors: Record<string, string> = {};

    // Validar array de items não vazio
    if (!items || !Array.isArray(items) || items.length === 0) {
      validationErrors.items = "Nenhum item selecionado";
    }

    // Validar nome (obrigatório e mínimo de 3 caracteres)
    if (!giver_name || giver_name.trim().length === 0) {
      validationErrors.giver_name = "Nome é obrigatório";
    } else if (giver_name.trim().length < 3) {
      validationErrors.giver_name = "Nome inválido (mínimo 3 caracteres)";
    }

    // Validar formato de telefone (10-11 dígitos numéricos)
    if (!giver_phone) {
      validationErrors.giver_phone =
        "WhatsApp é obrigatório para agradecimento";
    } else {
      const phoneDigits = giver_phone.replace(/\D/g, "");
      if (phoneDigits.length < 10 || phoneDigits.length > 11) {
        validationErrors.giver_phone = "WhatsApp inválido (use DDD + número)";
      }
    }

    // Validar tamanho da mensagem (máximo 200 caracteres)
    if (message_to_parents && message_to_parents.length > 200) {
      validationErrors.message_to_parents =
        "Mensagem muito longa (máximo 200 caracteres)";
    }

    // Retornar erros específicos para cada campo inválido
    if (Object.keys(validationErrors).length > 0) {
      return new Response(
        JSON.stringify({
          error: "Dados inválidos",
          details: validationErrors,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        },
      );
    }
    // --- FIM DA VALIDAÇÃO ---

    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    if (!MP_ACCESS_TOKEN) {
      throw new Error("Configuração de pagamento indisponível");
    }

    // Calcula valor total dos itens
    const totalAmount = items.reduce((sum: number, item: any) => {
      return sum + (Number(item.price) * (item.qty || 1));
    }, 0);

    // Função helper para sanitizar logs (esconde telefone)
    const sanitizeForLog = (data: any) => ({
      ...data,
      giver_phone: data.giver_phone
        ? data.giver_phone.slice(-4).padStart(11, "*")
        : undefined,
    });

    console.log(
      "[Payment] Iniciando checkout para:",
      sanitizeForLog({ giver_name, giver_phone }),
    );

    // Cria payload para a Checkout API do Mercado Pago
    const paymentData = {
      transaction_amount: totalAmount,
      description: `Presente para bebê - ${items.length} item(ns)`,
      payment_method_id: "pix",
      payer: {
        email: "guest@cria.app", // Email genérico para guest checkout
        first_name: giver_name.split(" ")[0],
        last_name: giver_name.split(" ").slice(1).join(" ") || giver_name,
      },
      metadata: {
        family_id: family_id || "",
        giver_name,
        giver_nickname: giver_nickname || "",
        giver_phone,
        message_to_parents: message_to_parents || "",
        item_ids: items.map((i: any) => i.id).join(","),
      },
      notification_url: `${
        Deno.env.get("SUPABASE_URL")
      }/functions/v1/mp-webhook`,
    };

    // Chama Checkout API v1/payments
    const mpResponse = await fetch("https://api.mercadopago.com/v1/payments", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": crypto.randomUUID(), // Previne duplicação
      },
      body: JSON.stringify(paymentData),
    });

    if (!mpResponse.ok) {
      const errorData = await mpResponse.json();
      console.error("[Payment] MP API Error:", sanitizeForLog(errorData));

      // Tratar erros 502/503 da API do Mercado Pago
      if (mpResponse.status >= 500) {
        return new Response(
          JSON.stringify({
            error:
              "Serviço de pagamento temporariamente indisponível. Tente novamente em alguns instantes.",
            retry: true,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 503,
          },
        );
      }

      throw new Error(
        "Pagamento não pôde ser processado. Verifique os dados e tente novamente.",
      );
    }

    const mpData = await mpResponse.json();
    const pixData = mpData.point_of_interaction?.transaction_data;

    console.log("[Payment] Created payment_id:", mpData.id);

    // Extrai dados do PIX e retorna
    return new Response(
      JSON.stringify({
        payment_id: mpData.id,
        qr_code: pixData?.qr_code || "",
        qr_code_base64: pixData?.qr_code_base64 || "",
        expiration_date: mpData.date_of_expiration,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error: any) {
    console.error("[Payment] Function error:", error.message);
    return new Response(
      JSON.stringify({
        error: error.message || "Erro interno do servidor",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    );
  }
});
