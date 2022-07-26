FROM python:3.7-slim

WORKDIR /app

COPY requirements.txt .
RUN apt update -y \
    && apt install -y \
      libpq-dev \
      gcc \
    && pip install --no-cache-dir -r requirements.txt \
    && apt clean -y

COPY . .

RUN useradd -U -d /app app
USER app

EXPOSE 5000
ENV FLASK_APP src/app.py
ENTRYPOINT [ "flask", "run", "-h", "0.0.0.0"]
