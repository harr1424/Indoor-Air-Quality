package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"golang.org/x/time/rate"
)

/*
Entry point for an application that stores device tokens (encrypted) and sends these registered
devices a push notification describing an air quality measurement that exceeded World Health Organization
guidelines.

Logic implementing rate limiting has been implemented so that the RaspberryPi may not send an APNs
request more than every 20 minutes.
*/

// limit push notifications to every 20 minutes
var limiter = rate.NewLimiter(rate.Every(1*time.Hour/3), 1)

func limit(limited http.HandlerFunc) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		if limiter.Allow() == false {
			http.Error(res, http.StatusText(429), http.StatusTooManyRequests)
			return
		}
		limited.ServeHTTP(res, req)
	}
}

func main() {
	handleCrypto(&key) // see encryption.go

	readTokensFromFile()                           // see tokens.go
	fmt.Println("All tokens (from file):", tokens) // Prints all currently registered tokens present in tokens.data

	http.HandleFunc("/", createNewToken)
	http.HandleFunc("/notify", limit(sendPushNotificationToAllTokens))

	log.Fatal(http.ListenAndServe("0.0.0.0:5050", nil))
	//log.Fatal(http.ListenAndServeTLS(":5050", "localhost.crt", "localhost.key", nil)) // support TLS when available
}
