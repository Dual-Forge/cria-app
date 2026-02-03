import google.generativeai as genai
import os
from dotenv import load_dotenv

# Carrega a sua API Key do arquivo .env
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("ERRO: Não achei a GEMINI_API_KEY no arquivo .env")
else:
    genai.configure(api_key=api_key)

    print("\n--- MODELOS DISPONÍVEIS NA SUA CONTA ---")
    try:
        for m in genai.list_models():
            # Mostra apenas modelos que geram texto (ignora os de imagem/embedding)
            if 'generateContent' in m.supported_generation_methods:
                print(f"- {m.name}")
    except Exception as e:
        print(f"Erro ao listar modelos: {e}")
    print("----------------------------------------\n")