ARG GO_VERSION=${GO_VERSION:-1.19}

FROM --platform=${BUILDPLATFORM:-linux/amd64}  golang:${GO_VERSION}-alpine AS builder

RUN apk update && apk add --no-cache git

WORKDIR /src
RUN cat /etc/passwd | grep nobody > /etc/passwd.nobody
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download

# Build the binary.
RUN --mount=type=bind,target=. \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -ldflags="-w -s" -tags=nomsgpack -o "/app" .


# build a small image
FROM --platform=${BUILDPLATFORM:-linux/amd64}  alpine

ENV TZ=Europe/Kyiv
RUN apk add tzdata

RUN apk add --no-cache bash curl && curl -1sLf \
'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash \
&& apk add --no-cache infisical && apk del bash curl

RUN mkdir /storage && chmod 777 -R /storage

COPY --from=builder /etc/passwd.nobody /etc/passwd
COPY --from=builder "/app" "/app"
WORKDIR /

# Run
USER nobody
ENTRYPOINT infisical run -- "/app"
