"""
This file uses the sds011 module to control an SDS011 dust sensor for the purpose of measuring indoor air quality. 
As measurements are taken, the logic contained in this file will adjust which light on the LED light strip is lit. 
If a measurement exceeding WHO guidelines is taken, a push notification request will be sent to the APNs server. 
"""

import atexit
import sys
import time
from datetime import datetime

import RPi.GPIO as GPIO
import requests
from serial import SerialException

import secrets
from sds011 import *

# Setup GPIO pins
GPIO.setmode(GPIO.BCM)
GPIO.setup(9, GPIO.OUT)
GPIO.setup(10, GPIO.OUT)
GPIO.setup(11, GPIO.OUT)


# Set all lights to off, call at light change
def reset_lights():
    GPIO.output(9, False)
    GPIO.output(10, False)
    GPIO.output(11, False)


# Set all lights to off and clean up GPIO, call at KeyboardInterrupt
def clean_exit():
    reset_lights()
    GPIO.cleanup()
    sys.exit(0)


def curr_time():
    return time.asctime(time.localtime())


def update_lights(fine, coarse):
    """
    Called as measurements occur, will set the appropriate light depending upon
    air quality measurement
    @:param float fine: PM2.5 concentration
    @:param float coarse: PM10 concentration
    """

    reset_lights()

    # poor air quality lights up red
    if fine >= 5.0 or coarse >= 15:
        GPIO.output(9, True)
        print(f"Set red light on {fine} or {coarse}")

    # moderate air quality lights up yellow
    elif fine >= 3.0 or coarse >= 10:
        GPIO.output(10, True)
        print(f"Set yellow light on {fine} or {coarse}")

    # else lights up green
    else:
        GPIO.output(11, True)
        print(f"Set green light on {fine} or {coarse}")


def take_measurements():
    """
    Collects one measurement of air quality each ten seconds.
    Sets lights appropriately. 
    Contacts APNs server to request a push notification if measurement exceeds WHO guidelines. 
    @:param str measurement_type: What type of measurement the file contains
    @:param int num_iterations: How many times to perform measurement before uploading
    """

    while True:
        """
        Multiple threads attempting to access the sensor at the same may result in a race condition, 
        fortunately the Serial package avoids this but will throw an exception. Handle by waiting one second, 
        then re-attempting the measurement. 

        Note that while this file does not use multiple threads, the code in this file will execute 
        in tandem with other multi-threaded code. 
        """
        try:
            fine_particles, coarse_particles = sensor.query()
        except SerialException:
            time.sleep(1)
            fine_particles, coarse_particles = sensor.query()

        update_lights(fine_particles, coarse_particles)

        # contact APNS server to send an alert immediately if a measurement exceeds WHO guidelines:
        # if fine_particles >= 5:
        #     hour_minute = datetime.now().strftime("%I:%M %p")
        #     pollutant = "PM2.5"
        #     measurement = str(fine_particles)

        #     r = requests.post(secrets.endpoint, json={"time": hour_minute, "pollutant": pollutant, "value": measurement})

        #     print(f"{curr_time()}: Sent APN request with status code {r.status_code} returned")

        # if coarse_particles >= 15:
        #     hour_minute = datetime.now().strftime("%I:%M %p")
        #     pollutant = "PM10"
        #     measurement = str(coarse_particles)

        #     r = requests.post(secrets.endpoint, json={"time": hour_minute, "pollutant": pollutant, "value": measurement})

        #     print(f"{curr_time()}: Sent APN request with status code {r.status_code} returned")

        time.sleep(10)


if __name__ == '__main__':
    atexit.register(clean_exit)
    sensor = SDS011("/dev/ttyUSB0")
    sensor.sleep(sleep=False)
    print("Preparing sensor...")
    time.sleep(15)
    print("Sensor is now running:")
    take_measurements()