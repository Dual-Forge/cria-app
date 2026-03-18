import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { items, family_id, giver_name, giver_nickname, giver_phone, message_to_parents } = await req.json();

    const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN');
    if (!MP_ACCESS_TOKEN) {
      throw new Error('Mercado Pago Access Token not configured (Secret MP_ACCESS_TOKEN missing)');
    }

    const mpItems = items.map((item: any) => ({
      title: item.name,
      quantity: item.qty || 1,
      unit_price: Number(item.price),
      currency_id: 'BRL',
    }));

    const preferenceData = {
      items: mpItems,
      back_urls: {
        success: `https://web-jade-ten-51.vercel.app/presentes/${family_id}?payment=success`,
        failure: `https://web-jade-ten-51.vercel.app/presentes/${family_id}?payment=failure`,
        pending: `https://web-jade-ten-51.vercel.app/presentes/${family_id}?payment=pending`
      },
      auto_return: "approved",
      notification_url: "https://drkuxfafxoruuvszowld.supabase.co/functions/v1/mp-webhook",
      payment_methods: {
        excluded_payment_types: [
          { id: "ticket" } // Exclui boleto (demora dias pra aprovar, atrapalha o mural)
        ],
        installments: 6
      },
      metadata: {          
        family_id,
        giver_name,
        giver_nickname,
        giver_phone: giver_phone || '',
        message_to_parents: message_to_parents || '',
        item_ids: items.map((i:any) => i.id).join(','),
      }
    };

    const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${MP_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(preferenceData),
    });

    if (!mpResponse.ok) {
        const errorData = await mpResponse.text();
        console.error("MP Error:", errorData);
        throw new Error(`MP Error ${mpResponse.status}: Falha ao gerar link do Mercado Pago`);
    }

    const mpData = await mpResponse.json();

    return new Response(JSON.stringify({ init_point: mpData.init_point }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
