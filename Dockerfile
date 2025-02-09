FROM golang:1.20-buster as builder

ARG TARGETPLATFORM
ARG TARGETARCH
RUN echo building for "$TARGETPLATFORM"

WORKDIR /go/src/app

COPY go.mod go.mod
COPY go.sum go.sum
# download if above files changed
RUN go mod download

# Copy the go source
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY version/ version/
COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH GO111MODULE=on go build -ldflags '-w -s -buildid=' -a -o plugnmeet-server ./cmd/server

FROM debian:buster-slim

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt update && \
    apt install --no-install-recommends -y wget libreoffice mupdf-tools && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
RUN groupadd app && useradd -g app app
USER app
WORKDIR /usr/app

COPY --from=builder /go/src/app/config_local.yaml /usr/app/config.yaml
COPY --from=builder /go/src/app/client/ /usr/app/client/
COPY --from=builder /go/src/app/client/assets/config_local.js /usr/app/client/assets/config.js
COPY --from=builder /go/src/app/plugnmeet-server /usr/app/plugnmeet-server

# Run the binary.
CMD ["./plugnmeet-server"]
