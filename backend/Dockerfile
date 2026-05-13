FROM golang:1.26.3-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /main ./cmd

FROM alpine:latest

WORKDIR /

COPY --from=builder /main .

EXPOSE 8080

CMD ["/main"]