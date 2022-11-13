package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/sideshow/apns2"
	PAYLOAD "github.com/sideshow/apns2/payload"
	APNS "github.com/sideshow/apns2/token"
)

/*
This file contains the definition of an alert struct and a methods used to send a push notification request
to Apple Push Notification services (APNs). The alert struct is used to hold information received from the
RaspberryPi describing a measurement that exceeded World Health Organization's guidelines on air quality.
This information is bound to the alert struct from a POST request containing JSON data when the /notify endpoint is
contacted. See main.go for further context.
*/

// Represents alert information received from RaspberryPi
// Used to display information about a specific measurement
type alert struct {
	Time      string `json:"time"`
	Pollutant string `json:"pollutant"`
	Value     string `json:"value"`
}

// Called when the /notify endpoint is contacted
// Binds posted JSON to a new alert struct
// Creates APNs request from alert struct
func sendPushNotificationToAllTokens(res http.ResponseWriter, req *http.Request) {
	var newAlert alert

	decoder := json.NewDecoder(req.Body)

	if err := decoder.Decode(&newAlert); err != nil {
		log.Println("Could not create new alert frpm request body:", err)
		return
	}

	// load signing key from file
	authKey, err := APNS.AuthKeyFromFile("apnkey.p8")
	if err != nil {
		log.Println("Token Error:", err)
	}

	// Generate JWT used for APNs
	requestToken := &APNS.Token{
		AuthKey: authKey,
		KeyID:   signingKey,
		TeamID:  teamID,
	}

	// Construct alert information from alert struct
	alertSubtitle := fmt.Sprintf("%s of %s measured %s", newAlert.Pollutant, newAlert.Value, newAlert.Time)
	payload := PAYLOAD.NewPayload().Alert("Air Quality Alert").AlertSubtitle(alertSubtitle)

	// Ensure all tokens are unique before sending an alert to each device they correspond to
	tokenSet := removeDuplicateTokens(tokens)
	for i := range tokenSet {
		notification := &apns2.Notification{
			DeviceToken: tokenSet[i].ID,
			Topic:       "com.harr1424.AirQuality",
			Payload:     payload,
		}

		client := apns2.NewTokenClient(requestToken)
		result, err := client.Push(notification)
		if err != nil {
			log.Println("Error Sending Push Notification:", err)
		}
		log.Println("Sent notification with response:", result)
	}
	res.WriteHeader(http.StatusCreated) // respond with status code 201
}
