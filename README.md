# Indoor-Air-Quality
A project that uses an SDS011 sensor and RaspberryPi to measure indoor air quality.  Measurements are uploaded to Google Cloud Storage and visualized in an iOS app using Swift Charts. The RaspberryPi also contacts an API written in Go to contact Apple Push Notification Services (APNs) if a measurement exceeds World Health Organization guidelines for air quality.

<center>
![chart](https://user-images.githubusercontent.com/84741727/201821855-2bda613c-da7b-4bf3-9c1f-8b7f89a53291.png)
![alerts](https://user-images.githubusercontent.com/84741727/201821860-938e740e-a81d-4001-b63e-f6f5f463181c.png)
</center>


# Credit 
The sds011.py file present in the Python directory (used to control the sds011 sensor) was authored by Ivan Kalchev. View his module at https://github.com/ikalchev/py-sds011

Creating and sending APNs requests via HTTP2 (Go/apns.go) was greatly simplified by the package: https://github.com/sideshow/apns2
