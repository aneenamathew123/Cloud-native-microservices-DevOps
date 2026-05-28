FROM python:3.12-slim-bookworm AS builder

WORKDIR /app

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt ./

RUN pip install --upgrade pip && \
    pip install --no-cache-dir "setuptools<82" && \
    pip install --no-cache-dir -r requirements.txt && \
    opentelemetry-bootstrap -a install

###############################################################

FROM python:3.12-slim-bookworm AS release

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
 
ENV PATH="/opt/venv/bin:$PATH"

COPY . .

ENV RECOMMENDATION_PORT=1010

ENV OTEL_SERVICE_NAME="my-recommendation-service"

ENV PRODUCT_CATALOG_ADDR=product-catalog:8088

CMD ["python", "recommendation_server.py"]