# docker buildx build --platform linux/amd64,linux/arm64 -t ohko4711/mev-boost-relay --push .

# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.20 AS builder
ARG VERSION
ARG TARGETARCH
ARG TARGETOS
WORKDIR /build

# Cache for the modules
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/root/.cache/go-build go mod download

# Now adding all the code and start building
ADD . .
RUN --mount=type=cache,target=/root/.cache/go-build GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags "-s -X cmd.Version=$VERSION -X main.Version=$VERSION" -v -o mev-boost-relay .

FROM alpine:3.18
RUN apk add --no-cache libstdc++ libc6-compat
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/mev-boost-relay /app/mev-boost-relay
ENTRYPOINT ["/app/mev-boost-relay"]