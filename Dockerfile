ARG GO_VERSION=${GO_VERSION:-1.20}

FROM --platform=${BUILDPLATFORM:-linux/amd64}  golang:${GO_VERSION}-alpine AS builder
ARG USER=nobody

RUN apk update && apk add --no-cache git

WORKDIR /src

RUN cat /etc/passwd | grep "${USER}" > /etc/passwd.user
RUN --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# Build the binary.
RUN --mount=type=bind,target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -ldflags="-w -s" -tags=nomsgpack -o "/app" .


# build a small image
FROM --platform=${BUILDPLATFORM:-linux/amd64}  alpine
ARG USER=nobody

ENV TZ=Europe/Kyiv
RUN apk add tzdata

COPY --from=builder /etc/passwd.user /etc/passwd
COPY --from=builder "/app" "/app"
WORKDIR /

USER ${USER}
ENTRYPOINT ["/app"]
