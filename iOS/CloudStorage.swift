/*
 Created by John Harrington October, 2022
 
 This file is responsible for retrieving all measurement files stored in Cloud Storage.
 
 Additionally, the name of hourly measurement files are modified to be more readable, and
 hourly measurements from past dates are not displayed and deleted from Cloud Storage.
 */


import SwiftUI
import FirebaseCore
import FirebaseStorage

public class CloudStorage: ObservableObject {
    
    let storage = Storage.storage() // a reference to the Cloud Storage bucket used in this project
    
    /*
     Create arrays of StorageReference types for each measurement interval
     */
    @Published public var hourlyItems = [StorageReference]()
    @Published public var dailyItems = [StorageReference]()
    @Published public var weeklyItems = [StorageReference]()
    @Published public var monthlyItems = [StorageReference]()
    
    func format_date(_ string: String) -> Date {
        let dateAsString = string
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d HH:mm:ss y"
        df.timeZone = TimeZone(identifier: "MST")
        df.locale = Locale(identifier: "en_US_POSIX")
        
        if let formattedDate = df.date(from: dateAsString) {
            return formattedDate
        } else {
            fatalError("Could not format \(dateAsString)")
        }
    }
    
    init() {
        Task(priority: .high) {
            let ref = storage.reference()
            ref.listAll { (result, error) in
                if let error = error {
                    print(error)
                }
                if let result = result {
                    /* measurement files are prefixed by the intervals in which they were
                     taken: hourly, daily, weekly, and monthly.
                     */
                    for prefix in result.prefixes {
                        prefix.listAll { result, error in
                            if let error = error {
                                print(error)
                            }
                            switch prefix.name {
                                
                            case "hourly":
                                if let result = result {
                                    for item in result.items {
                                        /*
                                         Convert the StorageReference name to a date in order to compare it
                                         to the current date:
                                         */
                                        let fileName = item.name
                                        let beginSubString = fileName.index(fileName.startIndex, offsetBy: 0)
                                        let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                                        let range = beginSubString..<endSubString
                                        let subString = fileName[range]
                                        let stringDescribingDate = String(subString)
                                        let measurementDate = self.format_date(stringDescribingDate)
                                        
                                        /*
                                         Hourly measurements accumulate fast, compare the date of the measurement
                                         to the current date, and if they are not equal, delete the measurement.
                                         */
                                        let currentDate = NSDate()
                                        
                                        let currentDay = Calendar.current.dateComponents([.day, .month, .year], from: currentDate as Date)
                                        let measurementDay = Calendar.current.dateComponents([.day, .month, .year], from: measurementDate)
                                        
                                        if (measurementDay == currentDay) { // only append hourly measurements for the current day
                                            self.hourlyItems.append(item)
                                        }
                                        else { // delete the measurements from prior days
                                            item.delete { error in
                                                if let error = error{
                                                    print("Could not delete expired hourly measurement: \(error)")
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            case "daily":
                                if let result = result {
                                    
                                    /*
                                     Create a dictionary containing the date a measurement began as keys
                                     and StorageReference object corresponding to that measurement as values.
                                     */
                                    var measurementDict = [Date : StorageReference]()
                                    
                                    for item in result.items {
                                        let fileName = item.fullPath
                                        let beginSubString = fileName.index(fileName.startIndex, offsetBy: 6)
                                        let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                                        let range = beginSubString..<endSubString
                                        let subString = fileName[range]
                                        let stringDescribingDate = String(subString)
                                        let measurementDate = self.format_date(stringDescribingDate)
                                        
                                        measurementDict[measurementDate] = item
                                    }
                                    
                                    // Sort the dictionary ascending by key
                                    let sortedMeasurements = measurementDict.sorted( by: { $0.key < $1.key})
                                    
                                    // Add the measurements to the published array in sorted order
                                    for measurement in sortedMeasurements {
                                        self.dailyItems.append(measurement.value)
                                    }
                                }
                                
                            case "weekly":
                                if let result = result {
                                    
                                    /*
                                     Create a dictionary containing the date a measurement began as keys
                                     and StorageReference object corresponding to that measurement as values.
                                     */
                                    var measurementDict = [Date : StorageReference]()
                                    
                                    for item in result.items {
                                        let fileName = item.fullPath
                                        let beginSubString = fileName.index(fileName.startIndex, offsetBy: 7)
                                        let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                                        let range = beginSubString..<endSubString
                                        let subString = fileName[range]
                                        let stringDescribingDate = String(subString)
                                        let measurementDate = self.format_date(stringDescribingDate)
                                        
                                        measurementDict[measurementDate] = item
                                    }
                                    
                                    // Sort the dictionary ascending by key
                                    let sortedMeasurements = measurementDict.sorted( by: { $0.key < $1.key})
                                    
                                    // Add the measurements to the published array in sorted order
                                    for measurement in sortedMeasurements {
                                        self.weeklyItems.append(measurement.value)
                                    }
                                }
                                
                            case "monthly":
                                if let result = result {
                                    
                                    
                                    /*
                                     Create a dictionary containing the date a measurement began as keys
                                     and StorageReference object corresponding to that measurement as values.
                                     */
                                    var measurementDict = [Date : StorageReference]()
                                    
                                    for item in result.items {
                                        let fileName = item.fullPath
                                        let beginSubString = fileName.index(fileName.startIndex, offsetBy: 8)
                                        let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                                        let range = beginSubString..<endSubString
                                        let subString = fileName[range]
                                        let stringDescribingDate = String(subString)
                                        let measurementDate = self.format_date(stringDescribingDate)
                                        
                                        measurementDict[measurementDate] = item
                                    }
                                    
                                    // Sort the dictionary ascending by key
                                    let sortedMeasurements = measurementDict.sorted( by: { $0.key < $1.key})
                                    
                                    // Add the measurements to the published array in sorted order
                                    for measurement in sortedMeasurements {
                                        self.monthlyItems.append(measurement.value)
                                    }
                                }
                                
                            default:
                                print("Prefix of type \(prefix.name) was not added!!!")
                            }
                            
                        }
                    }
                }
            }
        }
    }
}
