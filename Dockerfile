# Build stage
FROM golang:1.21-alpine AS builder

# Install git and ca-certificates untuk dependency downloads
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage - minimal image
FROM alpine:latest

# Install ca-certificates untuk HTTPS calls
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user untuk security
RUN adduser -D -s /bin/sh -u 1001 appuser

WORKDIR /root/

# Copy binary dari build stage
COPY --from=builder /app/main .

# Copy migration files jika diperlukan
COPY --from=builder /app/db/migration ./db/migration

# Change ownership ke appuser
RUN chown -R appuser:appuser /root/

# Switch ke non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the binary
CMD ["./main"]