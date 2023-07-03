ARG GO_VERSION=${GO_VERSION:-1.19}

FROM --platform=${BUILDPLATFORM:-linux/amd64}  golang:${GO_VERSION}-alpine AS builder
ARG REPOSITORY_NAME=${REPOSITORY_NAME:-app}

RUN apk update && apk add --no-cache git

WORKDIR /src

COPY ./go.mod ./go.sum ./
RUN go mod download

COPY . .

RUN cat /etc/passwd | grep nobody > /etc/passwd.nobody

# Build the binary.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -tags=nomsgpack -o /${REPOSITORY_NAME} .

# build a small image
FROM --platform=${BUILDPLATFORM:-linux/amd64}  alpine

ENV TZ=Europe/Kyiv
RUN apk add tzdata

RUN mkdir /storage && chmod 777 -R /storage

COPY --from=builder /etc/passwd.nobody /etc/passwd
COPY --from=builder /${REPOSITORY_NAME} /${REPOSITORY_NAME}

# Run
USER nobody
ENTRYPOINT ["{${REPOSITORY_NAME}"]
