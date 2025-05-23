# ───────── Base Image ─────────
FROM python:3.9-slim as base

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ───────── System Setup ─────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    unzip \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# ───────── App Directory ─────────
WORKDIR /app

# ───────── Copy and Install Deps ─────────
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# ───────── Download Model from S3 ─────────
ARG MODEL_S3_URI
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION

ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    AWS_REGION=${AWS_REGION}

RUN mkdir -p models && \
    aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}" && \
    aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" && \
    aws configure set region "${AWS_REGION}" && \
    aws s3 cp "${MODEL_S3_URI}" models/test_pulse.keras

# ───────── Copy Application Code ─────────
COPY app.py .

# ───────── Command to Run ─────────
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]

# # ───────── Builder Stage ─────────
# FROM public.ecr.aws/lambda/python:3.9 AS builder
#
# # Install AWS CLI and Python deps
# RUN pip install --no-cache-dir awscli
#
# WORKDIR /build
#
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt --target ./python
#
# # Fetch model at build time
# ARG MODEL_S3_URI
# ARG AWS_ACCESS_KEY_ID
# ARG AWS_SECRET_ACCESS_KEY
# ARG AWS_REGION
#
# # Configure AWS and pull model
# RUN aws configure set aws_access_key_id     "${AWS_ACCESS_KEY_ID}" && \
#     aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" && \
#     aws configure set region                "${AWS_REGION}" && \
#     mkdir -p python/models && \
#     aws s3 cp "${MODEL_S3_URI}" python/models/test_pulse.keras
#
# COPY app.py .
#
# # ───────── Final Stage ─────────
# FROM public.ecr.aws/lambda/python:3.9
#
# # Copy in just the packages, model, and code
# COPY --from=builder /build/python /var/task
# COPY --from=builder /build/app.py /var/task/app.py
#
#
# # Lambda handler remains the same
# CMD ["app.handler"]

# # Dockerfile for AWS Lambda Python 3.9 with FastAPI and TensorFlow
# FROM public.ecr.aws/lambda/python:3.9

# # Install AWS CLI to pull model from S3
# RUN pip install --no-cache-dir awscli

# WORKDIR /var/task

# # Copy and install dependencies
# COPY requirements.txt ./
# RUN pip install --no-cache-dir -r requirements.txt --target "/var/task"

# # Copy application code
# COPY app.py ./

# # Build‐time args for S3 and AWS auth
# ARG MODEL_S3_URI
# ARG AWS_ACCESS_KEY_ID
# ARG AWS_SECRET_ACCESS_KEY
# ARG AWS_REGION

# # Configure AWS CLI inside the image, then fetch the model
# RUN aws configure set aws_access_key_id     "${AWS_ACCESS_KEY_ID}" && \
#     aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" && \
#     aws configure set region                "${AWS_REGION}" && \
#     mkdir -p models && \
#     aws s3 cp "${MODEL_S3_URI}" models/my_model.keras

# # Lambda entrypoint
# CMD ["app.handler"]
