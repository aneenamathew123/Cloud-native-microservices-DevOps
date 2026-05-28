## We can try a multi-stage build to reduce the size of the final image
FROM golang:1.24.2 AS builder

WORKDIR /app

RUN go version

# Downloading dependencies first to leverage Docker cache. If go.mod or go.sum changes, only then it will re-download dependencies.
COPY go.mod go.sum ./
RUN go mod download
# COPY genproto/oteldemo/ ./genproto/oteldemo/
# COPY main.go ./

COPY . .
#Build the Go application. CGO_ENABLED=0 ensures that the binary is statically linked, which is necessary for running in a scratch container. 
#GOOS=linux ensures that the binary is built for Linux, which is the target environment for our container.

RUN CGO_ENABLED=0 GOOS=linux go build -o product-catalog .
###################################################################

FROM alpine AS release

WORKDIR /app

COPY ./products ./products

COPY --from=builder /app/product-catalog ./

ENV PRODUCT_CATALOG_PORT=8088
CMD [ "./product-catalog" ]





