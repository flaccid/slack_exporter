FROM golang as builder
COPY . /go/src/github.com/flaccid/slack_exporter
WORKDIR /go/src/github.com/flaccid/slack_exporter
#RUN go mod init
RUN go get ./...
RUN CGO_ENABLED=0 GOOS=linux go build -o /tmp/slack_exporter main.go

FROM alpine
COPY --from=builder /tmp/slack_exporter /slack-exporter
RUN apk add ca-certificates
WORKDIR /
ENTRYPOINT ["./slack-exporter"]
