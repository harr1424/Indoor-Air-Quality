# Indoor-Air-Quality
A project that uses an SDS011 sensor and RaspberryPi to measure indoor air quality.  Measurements are uploaded to Google Cloud Storage and visualized in an iOS app using Swift Charts. The RaspberryPi also contacts an API written in Go to contact Apple Push Notification Services (APNs) if a measurement exceeds World Health Organization guidelines for air quality.![image](https://user-images.githubusercontent.com/84741727/201529745-56fddbd1-fc02-427d-922c-122c55bd4d21.png)

# Credit 
The sds011.py file present in the Python directory was authored by Ivan Kalchev. View his module at https://github.com/ikalchev/py-sds011. This module was used to control the SDS011 sensor in this project. 

Creating and sending APNs requests via HTTP2 was greatly simplified by the package: https://github.com/sideshow/apns2
