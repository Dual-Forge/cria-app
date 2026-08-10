// ai-proxy — Proxy seguro para a API Groq (LLM).
//
// SEGURANÇA (IA-01/IA-02):
//  - verify_jwt = true no supabase/config.toml → apenas usuários autenticados
//    (JWT válido) alcançam este handler.
//  - A GROQ_API_KEY vive SOMENTE como variável de ambiente desta função
//    (Deno.env). Ela nunca é embarcada no bundle do app.
//
// Contrato de request (invocado via supabase.functions.invoke do Flutter):
//   {
//     "messages": [{ "role": "system|user|assistant", "content": "..." }],
//     "temperature": 0.7,       // opcional (default 0.7)
//     "json_mode": true         // optional, ativa response_format json_object
//   }
//
// Resposta: { "content": "<texto gerado>" } — pronto para o cliente.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const DEFAULT_MODEL = "llama-3.3-70b-versatile";

serve(async (req) => {
  // Rejeita qualquer método que não seja POST (também cobre OPTIONS).
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método não permitido." }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
    if (!GROQ_API_KEY) {
      console.error("[ai-proxy] GROQ_API_KEY não configurada no ambiente da função.");
      return new Response(
        JSON.stringify({ error: "Serviço de IA indisponível." }),
        { status: 503, headers: { "Content-Type": "application/json" } },
      );
    }

    const body = await req.json().catch(() => null);
    if (!body || !Array.isArray(body.messages) || body.messages.length === 0) {
      return new Response(
        JSON.stringify({ error: "Campo messages (não-vazio) é obrigatório." }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const payload: Record<string, unknown> = {
      model: DEFAULT_MODEL,
      messages: body.messages,
      temperature: typeof body.temperature === "number"
        ? body.temperature
        : 0.7,
      max_tokens: 1024,
    };

    if (body.json_mode === true) {
      payload["response_format"] = { type: "json_object" };
    }

    const groqResponse = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text();
      console.error(`[ai-proxy] Groq HTTP ${groqResponse.status}: ${errorText}`);
      return new Response(
        JSON.stringify({ error: "Falha ao gerar resposta da IA." }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const data = await groqResponse.json();
    const content: string | undefined =
      data?.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      return new Response(
        JSON.stringify({ error: "Resposta da IA sem conteúdo." }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({ content }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("[ai-proxy] Erro:", msg);
    return new Response(
      JSON.stringify({ error: "Erro interno do proxy de IA." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});