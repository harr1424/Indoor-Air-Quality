FROM golang:1.19.3-alpine3.16
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY ./go.mod /app/go.mod
COPY ./main.go /app/main.go
COPY ./apns.go /app/apns.go
COPY ./encryption.go /app/encryption.go
COPY ./tokens.go /app/tokens.go
COPY ./apnkey.p8 /app/apnkey.p8
RUN go mod tidy
RUN go build -o main .
EXPOSE 5050
CMD ["/app/main"]