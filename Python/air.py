import csv
import time
from threading import Thread

from google.cloud import storage
from serial import SerialException

import secrets
from sds011 import *

"""
This file uses the sds011 module to control an SDS011 dust sensor for the purpose of measuring indoor air quality. 
Air quality measurements are written to CSV files and uploaded to Cloud Storage. 
Measurement files correspond to hours, weeks, days, and months of measurements. 
Measurements for each time interval are collected on separate threads. 
"""


def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """
    Called by perform_upload()
    @:param str bucket_name: Name of bucket to upload file to
    @:param str source_file_name: Name of local file to upload
    @:param str destination_blob_name: Name of file once uploaded
    """
    storage_client = storage.Client(
        project=secrets.project_name
    )
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)


def perform_upload(file_object, source_filename, measurement_type):
    """
    Uploads a file to cloud storage
    @:param _io.TextIOWrapper file_object: The file object to close
    @:param str source_filename: The local file name of the file object
    @:param str measurement_type: What type of measurement the file contains
    """
    file_object.close()

    print(f"Uploading {measurement_type.upper()}")

    upload_blob(
        bucket_name=secrets.bucket_name,
        source_file_name=source_filename,
        destination_blob_name=f'{measurement_type}/{source_filename}'
    )


def curr_time():
    return time.asctime(time.localtime())


def take_measurements(measurement_type, num_iterations):
    """
    Collects one measurement of air quality each minute.
    @:param str measurement_type: What type of measurement the file contains
    @:param int num_iterations: How many times to perform measurement before uploading
    """

    while True:
        curr_file_name = f"{curr_time()}.csv"
        file = open(curr_file_name, "w")
        writer = csv.writer(file)

        for interval in range(num_iterations):
            """
            Multiple threads attempting to access the sensor at the same may result in a race condition, 
            fortunately the Serial package avoids this but will throw an exception. Handle by waiting one second, 
            then re-attempting the measurement. 
            """
            try:
                fine_particles, coarse_particles = sensor.query()
            except SerialException:
                time.sleep(1)
                fine_particles, coarse_particles = sensor.query()

            writer.writerow(["PM2.5", fine_particles, curr_time()])
            writer.writerow(["PM10", coarse_particles, curr_time()])

            print(
                f"{measurement_type.upper()} ({((interval / num_iterations) * 100):.2f}%): {fine_particles} {coarse_particles} {curr_time()}")

            time.sleep(60)

        perform_upload(file, curr_file_name, measurement_type)


if __name__ == '__main__':
    sensor = SDS011("/dev/ttyUSB0")
    sensor.sleep(sleep=False)
    print("Preparing sensor...")
    time.sleep(15)
    print("Sensor is now running:")

    threads = [Thread(target=take_measurements, args=['hourly', 60]),
               Thread(target=take_measurements, args=['daily', 1440]),
               Thread(target=take_measurements, args=['weekly', 10080]),
               Thread(target=take_measurements, args=['monthly', 43800])]

    for thread in threads:
        thread.start()