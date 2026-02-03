import os
import requests
import json
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from bs4 import BeautifulSoup
import google.generativeai as genai
from dotenv import load_dotenv

# Carrega variáveis de ambiente
load_dotenv()



# Configuração da IA
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# --- AQUI ESTÁ A LINHA QUE O ERRO DIZ QUE FALTA ---
app = FastAPI(title="Cria Backend API") 
# --------------------------------------------------
class ProductAnalysis(BaseModel):
    name: str | None = None
    price: float | None = None
    image_url: str | None = None  # <--- O campo novo da imagem

class PregnancyRequest(BaseModel):
    week: int
    diary_context: str | None = None

# ... (código existente da lista de compras ...)

# 2. Adicione esta NOVA ROTA no final do arquivo
@app.post("/get-pregnancy-tips")
def get_pregnancy_tips(payload: PregnancyRequest):
    try:
        # Usando o modelo configurado (gemini-2.5-flash ou o que estiver funcionando)
        model = genai.GenerativeModel('gemini-2.5-flash')
        
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
        
        response = model.generate_content(prompt)
        text_response = response.text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text_response)
        
        return data

    except Exception as e:
        print(f"Erro Gemini Dicas: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Modelos de Dados (Entrada)
class LinkRequest(BaseModel):
    url: str

class AdviceRequest(BaseModel):
    item_name: str
    age_range: str

# Rota de teste (Raiz)
@app.get("/")
def read_root():
    return {"message": "O Backend do Cria está ON! 🚀"}

# --- ENDPOINT 1: Analisador de Links de Compra ---
@app.post("/analyze-link")
def analyze_link(payload: LinkRequest):
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        # PROMPT BLINDADO
        prompt = f"""
        Acesse este link: {payload.url}
        
        Sua missão é extrair dados para uma lista de compras de bebê.
        
        1. NOME: Extraia o nome principal do produto (curto e direto).
        2. PREÇO: Encontre o PREÇO À VISTA (o menor valor de venda). 
           - IGNORE parcelas (ex: "12x de...").
           - IGNORE preço original riscado ("de R$ 200...").
           - Se tiver centavos, use ponto ou vírgula.
        3. IMAGEM: Pegue a URL da imagem principal (preferência terminada em .jpg ou .png).
        
        Retorne APENAS este JSON:
        {{
            "name": "Nome do Produto",
            "price_text": "139,90",  <-- Retorne como TEXTO exatamente como está no site
            "image_url": "https://..."
        }}
        """
        
        response = model.generate_content(prompt)
        # Limpeza do texto da resposta (remove crases e markdown)
        text_response = response.text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text_response)
        
        # --- TRATAMENTO INTELIGENTE DO PREÇO NO PYTHON ---
        raw_price = str(data.get("price_text", "0"))
        
        # 1. Remove "R$", espaços e símbolos de moeda
        clean_price = raw_price.replace("R$", "").replace("US$", "").strip()
        
        # 2. Arruma a pontuação do Brasil (1.200,50 -> 1200.50)
        if "," in clean_price and "." in clean_price: 
            clean_price = clean_price.replace(".", "") # Remove ponto de milhar
            clean_price = clean_price.replace(",", ".") # Troca vírgula por ponto
        elif "," in clean_price:
            clean_price = clean_price.replace(",", ".") # Troca vírgula simples
            
        # 3. Converte para float final
        try:
            final_price = float(clean_price)
        except:
            final_price = 0.0
            
        print(f"💰 Preço detectado: {raw_price} -> Convertido: {final_price}")
        print(f"🖼️ Imagem: {data.get('image_url')}")

        return ProductAnalysis(
            name=data.get("name"), 
            price=final_price,
            image_url=data.get("image_url")
        )

    except Exception as e:
        print(f"Erro: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- ENDPOINT 2: Consultor de Enxoval ---
@app.post("/get-advice")
def get_advice(payload: AdviceRequest):
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        prompt = f"""
        Contexto: Sou pai de primeira viagem montando enxoval.
        Item: {payload.item_name}
        Idade do bebê: {payload.age_range} (Meses)
        
        Ação:
        1. Estime a quantidade média mensal necessária desse item.
        2. Dê uma "Dica de Pai" curta e prática sobre esse item.
        
        Responda em texto simples, tom amigável e direto.
        """
        response = model.generate_content(prompt)
        return {"advice": response.text}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail="Erro na IA de conselhos.")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)