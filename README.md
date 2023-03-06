# Indoor-Air-Quality
A project that uses an SDS011 sensor and RaspberryPi to measure indoor air quality.  Measurements are uploaded to Google Cloud Storage and visualized in an iOS app using Swift Charts. The RaspberryPi contacts an API written in Go to contact Apple Push Notification Services (APNs) if a measurement exceeds World Health Organization guidelines for air quality. The Raspberry Pi also controls a Pi Traffic Light to display a light color corresponding to air quality. 

<br>

<p align="center">
      <img width="400" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/chart.png" alt="A chart displaying indoor air quality measurements">
       <spacer type="horizontal" width="200"></spacer>
    <img width="400" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/alerts.png" alt="Air quality alerts received on an iOS device">
    <img width="800" src="https://github.com/harr1424/Indoor-Air-Quality/blob/main/images/pi.png" alt="SDS011 sensor and Pi Traffic Light attached to a Raspberry Pi">
    
    ![69976284730__B51D1990-30C5-4CF4-A94F-BD9C23C1BBAC](https://user-images.githubusercontent.com/84741727/223009771-0c0ea712-d656-40a3-8e4c-ad687a2dae3c.png)


</p>



# Credit 
The sds011.py file present in the Python directory (used to control the sds011 sensor) was authored by Ivan Kalchev. View his module at https://github.com/ikalchev/py-sds011

Creating and sending APNs requests via HTTP2 (Go/apns.go) was greatly simplified by the package: https://github.com/sideshow/apns2
