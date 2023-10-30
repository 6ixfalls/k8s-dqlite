FROM ubuntu:jammy AS builder

# Setup golang
ENV GO_VERSION=1.21.3

RUN apt-get update
RUN apt-get install -y wget git gcc

ARG TARGETPLATFORM

RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  DL_ARCH=amd64  ;; \
         "linux/arm64")  DL_ARCH=arm64  ;; \
    esac \
 && wget -P /tmp "https://dl.google.com/go/go${GO_VERSION}.linux-${DL_ARCH}.tar.gz" -O go.tar.gz

RUN tar -C /usr/local -xzf "/tmp/go.tar.gz"
RUN rm "/tmp/go.tar.gz"

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

WORKDIR $GOPATH

# Setup k8s-dqlite

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common python3-launchpadlib && \
    rm -rf /var/lib/apt/lists/* && \
    add-apt-repository ppa:dqlite/dev && \
    apt-get update && \
    apt-get install -y libraft-dev libdqlite-dev libsqlite-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /go/src/github.com/rancher/kine
COPY . .

# Build k8s-dqlite
RUN CGO_LDFLAGS_ALLOW="-Wl,-z,now" go build -o /bin/k8s-dqlite -tags libsqlite3,dqlite k8s-dqlite.go

# Final run container
FROM alpine:3.18
COPY --from=builder /bin/k8s-dqlite /bin/k8s-dqlite
ENTRYPOINT ["/bin/k8s-dqlite"]