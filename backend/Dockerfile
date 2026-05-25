# Stage 1: Build & Runtime Environment
FROM python:3.11-slim

# Set environment variables for clean container output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

WORKDIR /backend

# Install core system dependencies, curl, and Node.js for Prisma Engine
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy database schema configuration
COPY prisma ./prisma

# Generate Prisma Client (runs node behind the scenes)
RUN python -m prisma generate

# Copy application source code
COPY . .

# Expose server listener port
EXPOSE 8000

# Start server worker
CMD ["uvicorn", "main.py:app", "--host", "0.0.0.0", "--port", "8000"]
