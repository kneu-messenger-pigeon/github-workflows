ARG GO_VERSION=${GO_VERSION:-1.19}
ARG REPOSITORY_NAME=${REPOSITORY_NAME:-app}

FROM --platform=${BUILDPLATFORM:-linux/amd64}  golang:${GO_VERSION}-alpine AS builder

RUN apk update && apk add --no-cache git

WORKDIR /src

COPY ./go.mod ./go.sum ./
RUN go mod download

COPY . .

RUN cat /etc/passwd | grep nobody > /etc/passwd.nobody

# Build the binary.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -tags=nomsgpack -o /app .

# build a small image
FROM --platform=${BUILDPLATFORM:-linux/amd64}  alpine
ARG REPOSITORY_NAME
ENV TZ=Europe/Kyiv
RUN apk add tzdata

RUN mkdir /storage && chmod 777 -R /storage

COPY --from=builder /etc/passwd.nobody /etc/passwd
COPY --from=builder /app "/${REPOSITORY_NAME}"

# Run
USER nobody
ENTRYPOINT ["/${REPOSITORY_NAME}"]
