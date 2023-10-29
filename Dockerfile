FROM ubuntu:jammy AS builder

ENV GO_VERSION=1.21.3

RUN apt-get update
RUN apt-get install -y wget git gcc

RUN wget -P /tmp "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"

RUN tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.linux-amd64.tar.gz"
RUN rm "/tmp/go${GO_VERSION}.linux-amd64.tar.gz"

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

WORKDIR $GOPATH

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

FROM alpine:3.18
COPY --from=builder /bin/k8s-dqlite /bin/k8s-dqlite
ENTRYPOINT ["/bin/k8s-dqlite"]