FROM golang:alpine AS build-env

RUN apk update && apk add --no-cache git

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download

COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags='-extldflags "-static"' -o app .

FROM scratch
WORKDIR /app
COPY --from=build-env /go/src/app/app .
ENTRYPOINT ["./app"]
