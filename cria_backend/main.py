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

app = FastAPI(title="Cria Backend API") 

# Modelos de Dados (Modelos Pydantic)
class ProductAnalysis(BaseModel):
    name: str | None = None
    price: float | None = None
    image_url: str | None = None

class PregnancyRequest(BaseModel):
    week: int
    diary_context: str | None = None

class LinkRequest(BaseModel):
    url: str

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
        model = genai.GenerativeModel('gemini-2.0-flash')
        
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
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        data = json.loads(response.text)
        return data

    except Exception as e:
        print(f"Erro Gemini Dicas: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- ENDPOINT: Analisador de Links de Compra (Web Scraper + IA) ---
@app.post("/analyze-link")
def analyze_link(payload: LinkRequest):
    try:
        # 1. Raspa a página usando requests e BeautifulSoup de forma robusta
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.8"
        }
        page_title = ""
        page_text = ""
        meta_image_url = ""
        meta_title = ""
        meta_price = ""
        
        try:
            req_response = requests.get(payload.url, headers=headers, timeout=10)
            req_response.raise_for_status()
            soup = BeautifulSoup(req_response.text, "html.parser")
            
            # Limpa scripts e estilos para reduzir tokens desnecessários
            for element in soup(["script", "style"]):
                element.decompose()
            
            page_title = soup.title.string.strip() if soup.title else ""
            page_text = soup.get_text()
            # Remove excesso de quebras de linha e espaços em branco
            page_text = " ".join(page_text.split())[:5000]
            
            # Extrai metadados úteis que lojas costumam disponibilizar
            meta_og_image = soup.find("meta", property="og:image") or soup.find("meta", attrs={"name": "twitter:image"})
            meta_image_url = meta_og_image["content"] if meta_og_image else ""
            
            meta_og_title = soup.find("meta", property="og:title") or soup.find("meta", attrs={"name": "twitter:title"})
            meta_title = meta_og_title["content"] if meta_og_title else ""
            
            meta_og_price = (
                soup.find("meta", property="product:price:amount") or 
                soup.find("meta", property="product:sale_price:amount") or
                soup.find("meta", attrs={"name": "twitter:data1"})
            )
            meta_price = meta_og_price["content"] if meta_og_price else ""
            
        except Exception as e_scrape:
            print(f"⚠️ Alerta: Falha ao raspar a URL diretamente: {e_scrape}")
            # Continuamos para o Gemini tentar processar com o contexto que tiver
        
        model = genai.GenerativeModel('gemini-2.0-flash')
        
        prompt = f"""
        Você é um assistente de extração de dados especializado em e-commerce.
        Recebemos uma página de produto com a URL: {payload.url}
        
        Aqui estão as informações extraídas diretamente da página HTML do produto:
        - Título da Página: {page_title or meta_title}
        - Meta Imagem sugerida: {meta_image_url}
        - Meta Preço sugerido: {meta_price}
        - Conteúdo de texto da página (primeiros 5000 caracteres):
        \"\"\"
        {page_text}
        \"\"\"
        
        Sua missão é extrair e organizar os dados em JSON para uma lista de compras de bebê:
        1. name: Nome principal e curto do produto (ex: "Fralda Pampers Confort Sec G 60 Unidades", não o título gigante com palavras-chave de SEO).
        2. price_text: Encontre o PREÇO À VISTA (o menor valor de venda, ex: "139,90").
           - IGNORE parcelas (ex: "12x de...").
           - IGNORE preço original riscado ("de R$ 200...").
        3. image_url: A URL da imagem principal do produto. Se a "Meta Imagem sugerida" fornecida acima for válida, dê preferência a ela. Caso contrário, encontre uma URL de imagem válida do produto no conteúdo da página.
        
        Retorne APENAS este JSON:
        {{
            "name": "Nome do Produto",
            "price_text": "139,90",
            "image_url": "https://..."
        }}
        """
        
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        data = json.loads(response.text)
        
        # --- TRATAMENTO INTELIGENTE DO PREÇO NO PYTHON ---
        raw_price = str(data.get("price_text", "0"))
        
        clean_price = raw_price.replace("R$", "").replace("US$", "").strip()
        
        if "," in clean_price and "." in clean_price: 
            clean_price = clean_price.replace(".", "")
            clean_price = clean_price.replace(",", ".")
        elif "," in clean_price:
            clean_price = clean_price.replace(",", ".")
            
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
        print(f"Erro analyze-link: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- ENDPOINT: Consultor de Enxoval ---
@app.post("/get-advice")
def get_advice(payload: AdviceRequest):
    try:
        model = genai.GenerativeModel('gemini-2.0-flash')
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
        print(f"Erro get-advice: {e}")
        raise HTTPException(status_code=500, detail="Erro na IA de conselhos.")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)