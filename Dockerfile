FROM golang:1.21.3-bookworm AS builder

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common python3-launchpadlib && \
    rm -rf /var/lib/apt/lists/* && \
    add-apt-repository ppa:dqlite/dev && \
    apt-get update && \
    apt-get install -y libraft-dev libdqlite-dev libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /go/src/github.com/canonical/k8s-dqlite
COPY . .

# Build k8s-dqlite
RUN export CGO_LDFLAGS_ALLOW="-Wl,-z,now" && \
    go build -o /bin/k8s-dqlite -tags libsqlite3,dqlite k8s-dqlite.go

FROM alpine:3.18
COPY --from=builder /bin/k8s-dqlite /bin/k8s-dqlite
ENTRYPOINT ["/bin/k8s-dqlite"]