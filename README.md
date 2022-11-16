# Indoor-Air-Quality
A project that uses an SDS011 sensor and RaspberryPi to measure indoor air quality.  Measurements are uploaded to Google Cloud Storage and visualized in an iOS app using Swift Charts. The RaspberryPi also contacts an API written in Go to contact Apple Push Notification Services (APNs) if a measurement exceeds World Health Organization guidelines for air quality.

<br>

<p align="center">
      <img width="400" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/chart.png" alt="A chart displaying indoor air quality measurements">
       <spacer type="horizontal" width="100"></spacer>
    <img width="400" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/alerts.png" alt="Air quality alerts received on an iOS device">
    
        <img width="400" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/pi.png" alt="SDS011 sensor and Pi Traffic Light attached to a Raspberry Pi">

</p>



# Credit 
The sds011.py file present in the Python directory (used to control the sds011 sensor) was authored by Ivan Kalchev. View his module at https://github.com/ikalchev/py-sds011

Creating and sending APNs requests via HTTP2 (Go/apns.go) was greatly simplified by the package: https://github.com/sideshow/apns2
