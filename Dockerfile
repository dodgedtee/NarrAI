FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/app/.cache/huggingface

WORKDIR /app

# libgomp1 is required at runtime by faiss-cpu and PyTorch
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install CPU-only PyTorch first to avoid pulling large CUDA dependencies
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch \
    || pip install --no-cache-dir torch

RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the embedding model used by core/embedder.py and core/rag.py
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

COPY . .

RUN mkdir -p /app/data /app/sessions

EXPOSE 8000

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
