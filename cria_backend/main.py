import os
import json
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from groq import Groq
from fastapi.middleware.cors import CORSMiddleware

# Carrega variáveis de ambiente
load_dotenv()

# Configuração da IA
client_groq = Groq(api_key=os.getenv("GROQ_API_KEY"))
GROQ_MODEL = "llama-3.3-70b-versatile"

app = FastAPI(title="Cria Backend API") 

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your Vercel domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos de Dados (Modelos Pydantic)
class PregnancyRequest(BaseModel):
    week: int
    diary_context: str | None = None

class AdviceRequest(BaseModel):
    item_name: str
    age_range: str

# Rota de teste (Raiz)
@app.get("/")
def read_root():
    return {"message": "O Backend do Cria está ON! 🚀"}

# --- ENDPOINT: Dicas de Gravidez Semanais ---
@app.post("/get-pregnancy-tips")
def get_pregnancy_tips(payload: PregnancyRequest):
    try:
        contexto_diario = f"Contexto do diário da mãe: '{payload.diary_context}'" if payload.diary_context else "A mãe não fez anotações recentes."

        prompt = f"""
        Você é uma especialista em maternidade e saúde gestacional.
        
        PERFIL DA MÃE:
        - Estágio: {payload.week} semanas de gestação.
        - {contexto_diario}
        
        Gere 4 dicas CURTAS e DIRETAS (máximo 15 palavras cada) personalizadas para o momento dela:
        1. Dieta/Nutrição (baseada na semana e sintomas).
        2. Exercícios/Movimento (seguro para a semana).
        3. Bem-estar/Mental (motivacional ou relaxamento).
        4. Foco da Semana (o que acontece com o bebê ou corpo agora).
        
        Retorne APENAS um JSON estrito neste formato:
        {{
            "diet": "Texto da dica de dieta",
            "exercise": "Texto da dica de exercício",
            "mental": "Texto da dica mental",
            "baby_focus": "Texto do foco da semana"
        }}
        """
        
        # Garante resposta JSON estruturada nativamente
        completion = client_groq.chat.completions.create(
            model=GROQ_MODEL,
            messages=[
                {"role": "system", "content": "Você responde APENAS com JSON válido, sem markdown."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"},
        )
        data = json.loads(completion.choices[0].message.content)
        return data

    except Exception as e:
        print(f"Erro Gemini Dicas: {e}")
        raise HTTPException(status_code=500, detail=str(e))



# --- ENDPOINT: Consultor de Enxoval ---
@app.post("/get-advice")
def get_advice(payload: AdviceRequest):
    try:
        prompt = f"""
        Contexto: Sou pai de primeira viagem montando enxoval.
        Item: {payload.item_name}
        Idade do bebê: {payload.age_range} (Meses)
        
        Ação:
        1. Estime a quantidade média mensal necessária desse item.
        2. Dê uma "Dica de Pai" curta e prática sobre esse item.
        
        Responda em texto simples, tom amigável e direto.
        """
        completion = client_groq.chat.completions.create(
            model=GROQ_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )
        return {"advice": completion.choices[0].message.content}
        
    except Exception as e:
        print(f"Erro get-advice: {e}")
        raise HTTPException(status_code=500, detail="Erro na IA de conselhos.")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)