import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Tratamento do CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Pega o payment_id direto da URL (ex: ?payment_id=123456789)
    const url = new URL(req.url);
    const paymentId = url.searchParams.get("payment_id");

    // Validação
    if (!paymentId) {
      throw new Error("payment_id é obrigatório");
    }

    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    if (!MP_ACCESS_TOKEN) {
      throw new Error("Configuração indisponível");
    }

    // Consulta status direto no Mercado Pago
    const mpResponse = await fetch(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: { "Authorization": `Bearer ${MP_ACCESS_TOKEN}` },
      },
    );

    if (!mpResponse.ok) {
      throw new Error("Erro ao consultar status do pagamento");
    }

    const paymentData = await mpResponse.json();

    // Retorna apenas o que o frontend precisa para atualizar a tela
    return new Response(
      JSON.stringify({
        status: paymentData.status,
        status_detail: paymentData.status_detail,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error: any) {
    console.error("Status check error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
