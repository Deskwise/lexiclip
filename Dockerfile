FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
# python3-venv is needed for venv creation
# file, wget, fuse are needed for appimagetool
# libgl1-mesa-glx is often needed for Qt apps
# tesseract-ocr is needed for the app itself
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tesseract-ocr \
    libtesseract-dev \
    file \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Create venv and install dependencies
RUN python3 -m venv venv && \
    ./venv/bin/pip install --no-cache-dir -r requirements.txt && \
    ./venv/bin/pip install pyinstaller

# Copy source code
COPY . .

# Make build script executable
RUN chmod +x build_appimage.sh

# Default command to build
CMD ["./build_appimage.sh"]
