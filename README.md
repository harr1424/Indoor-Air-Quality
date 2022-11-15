# Indoor-Air-Quality
A project that uses an SDS011 sensor and RaspberryPi to measure indoor air quality.  Measurements are uploaded to Google Cloud Storage and visualized in an iOS app using Swift Charts. The RaspberryPi also contacts an API written in Go to contact Apple Push Notification Services (APNs) if a measurement exceeds World Health Organization guidelines for air quality.

![chart](https://user-images.githubusercontent.com/84741727/201821674-db1f65b1-c701-4920-b791-a9f4f44ebcf7.png)
![alerts](https://user-images.githubusercontent.com/84741727/201821685-18a11da2-beba-4b20-913a-fa3d0730830f.png)



# Credit 
The sds011.py file present in the Python directory (used to control the sds011 sensor) was authored by Ivan Kalchev. View his module at https://github.com/ikalchev/py-sds011

Creating and sending APNs requests via HTTP2 (Go/apns.go) was greatly simplified by the package: https://github.com/sideshow/apns2
