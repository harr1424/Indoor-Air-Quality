import os
from flask import Flask
import firebase_admin
from firebase_admin import credentials, storage
import csv
import secrets

"""
This file implements a Flask application with one endpoint (/). 
When this endpoint receives an HTTP GET request, it will analyze all files in cloud storage to determine if air 
quality guidelines set by the WHO have been exceeded. If so, the JSON response will include an "alert": true
field that will be used to trigger an alert in an iOS app that contacts the API endpoint. Additionally, the JSON
response will contain relevant information about the measurement responsible for the alert such as what time the 
measurement occurred, the offending pollutant, and the measured concentration of that pollutant. 
"""

app = Flask(__name__)

"""
Google Cloud Storage Variables
"""
cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred, {'storageBucket': secrets.bucket_name})
bucket = storage.bucket()

"""
These variables will be part of JSON response served by this API
"""
alert = False
pollutant = ''
value = 0.0
measurement_time = ''
skipped_prev_files = False

"""
Keep track of viewed files to avoid duplicate alerts
"""
viewed_files = []


def reset_alert():
    global alert
    global pollutant
    global value
    global measurement_time
    global skipped_prev_files
    global viewed_files
    alert = False
    pollutant = ''
    value = 0.0
    measurement_time = ''


def read_new_files():
    global alert
    global pollutant
    global value
    global measurement_time
    global skipped_prev_files
    global viewed_files

    files = list(bucket.list_blobs())

    """
    For each file in the bucket, determine if the file has been read previously. 
    If it has, skip it, and set skipped_prev_files to True.
    
    If the file has not been read before, download it locally and parse the CSV 
    searching for rows that contain a measurement exceeding WHO guidelines.
    Lastly, add the file to the viewed_files list. 
    """
    for each in files:

        if each.name in viewed_files:
            skipped_prev_files = True

        elif each.name not in viewed_files:
            dest = f"./blobs/{each.name}"
            each.download_to_filename(dest)

            with open(dest, 'r') as hourly:
                print(f"Reading {each}")
                num_row = 0
                reader = csv.reader(hourly, delimiter=',')
                for row in reader:
                    if row[0] == 'PM2.5':
                        measurement = float(row[1])
                        if measurement >= 5.0:
                            alert = True
                            value = measurement
                            pollutant = 'PM2.5'
                            measurement_time = row[2]
                            print(f"Alert at {measurement_time} for {pollutant} measured at {value}")
                    elif row[0] == 'PM10':
                        measurement = float(row[1])
                        if measurement >= 15.0:
                            alert = True
                            value = measurement
                            pollutant = 'PM10'
                            measurement_time = row[2]
                            print(f"Alert at {measurement_time} for {pollutant} measured at {value}")
                    else:
                        print(f"ERROR Unexpected value found on line {num_row}")

                    num_row += 1

            viewed_files.append(each.name)


@app.route("/")
def check_alert():
    reset_alert()
    read_new_files()
    return {
        "alert": alert,
        "pollutant": pollutant,
        "value": value,
        "time": measurement_time,
        "files_seen": viewed_files,
        "prev_files_skipped": skipped_prev_files
    }


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
