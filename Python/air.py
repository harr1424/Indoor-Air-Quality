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
    Uploads a local file to a specified bucket using a specified name. 
    @:param str bucket_name: Name of bucket to upload file to
    @:param str source_file_name: Name of local file to upload
    @:param str destination_blob_name: Name of file as shown in cloud storage
    """
    storage_client = storage.Client(
        project=secrets.project_name
    )
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)


def perform_upload(file_object, source_filename, measurement_type):
    """
    Closes a local file file object in preparation for uploading to 
    cloud storage. Prints the measurement interval of this file upload 
    to std::out and prepends the interval type to the filename. 
    @:param _io.TextIOWrapper file_object: The file object to close
    @:param str source_filename: The local file name of the file object
    @:param str measurement_type: What type of measurement the file contains (hourly, daily, weekly, or monthly)
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


def take_measurements(measurement_type):
    """
    Opens a measurement file object and sets num_iterations to collect measurements to fill a corresponding time interval. 
    Collects one measurement of air quality each minute, until num_iterations is reached. Then the file object, 
    a CSV file describing measurements, will be uploaded to cloud storage. 
    @:param str measurement_type: What type of measurement the file contains (hourly, daily, weekly, or monthly)
    """

    if measurement_type == 'hourly':
        num_iterations = 60
    elif measurement_type == 'daily': 
        num_iterations = 1440
    elif measurement_type == 'weekly':
        num_iterations = 10080
    elif measurement_type == 'monthly':
        num_iterations = 43800
    else:
        raise Exception(f"Invalid measurement_type provided: {measurement_type}. Must be hourly, daily, weekly, or monthly.")

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

    # Threading is used to allow for hourly, daily, weekly, and monthly files to be written to and uploaded synchronously. 
    threads = [Thread(target=take_measurements, args=['hourly']),
               Thread(target=take_measurements, args=['daily']),
               Thread(target=take_measurements, args=['weekly']),
               Thread(target=take_measurements, args=['monthly'])]

    for thread in threads:
        thread.start()