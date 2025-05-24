# ───── Base Stage: Install Python and dependencies ─────
FROM python:3.9-slim AS builder

# Environment configuration
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install OS packages (curl, unzip, awscli)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Add build arguments for AWS credentials and model URI
ARG MODEL_S3_URI
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION

# Environment variables for AWS
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_REGION=${AWS_REGION}

# Download the model from S3
RUN mkdir -p models && \
    aws s3 cp ${MODEL_S3_URI} models/test_pulse.keras

# Copy application code
COPY . .

# ───── Final Stage: Minimal Image with Only App ─────
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy Python packages and binaries from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy app code
COPY --from=builder /app /app

# Expose the port for FastAPI
EXPOSE 8000

# Start the FastAPI app with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port","8000"]
## ───── Base Stage: Install Python and dependencies ─────
#FROM python:3.9-slim AS builder
#
## Set environment variables
#ENV PYTHONDONTWRITEBYTECODE=1
#ENV PYTHONUNBUFFERED=1
#
## Install OS packages
#RUN apt-get update && apt-get install -y \
#    curl \
#    unzip \
#    awscli \
#    && rm -rf /var/lib/apt/lists/*
#
## Set working directory
#WORKDIR /app
#
## Copy requirement file and install Python dependencies
#COPY requirements.txt .
#RUN pip install --no-cache-dir -r requirements.txt
#
## Add build arguments for AWS credentials and model S3 path
#ARG MODEL_S3_URI
#ARG AWS_ACCESS_KEY_ID
#ARG AWS_SECRET_ACCESS_KEY
#ARG AWS_REGION
#
## Set environment variables for AWS CLI
#ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
#ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
#ENV AWS_REGION=${AWS_REGION}
#
## Download model from S3
#RUN mkdir -p models && \
#    aws s3 cp ${MODEL_S3_URI} models/test_pulse.keras
#
## Copy app code into image
#COPY . .
#
## ───── Final Stage: Clean, Run Uvicorn ─────
#FROM python:3.9-slim
#
#WORKDIR /app
#
## Copy installed packages and app files from builder stage
#COPY --from=builder /app /app
#
## Expose FastAPI port
#EXPOSE 8000
#
## Run the FastAPI app
#CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port","8000"]