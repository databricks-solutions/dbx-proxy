FROM python:3.12-slim

WORKDIR /app

COPY backends /app/backends

EXPOSE 443 5432
