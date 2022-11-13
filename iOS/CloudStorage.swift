/*
 Created by John Harrington October, 2022
 
 This file is responsible for retreiving all measurement files stored in Cloud Storage.
 
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
        return df.date(from: dateAsString)!
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
                                         Format how hourly measurement files are displayed to the user as a
                                         more readable date format: Nov 6. 2022 at 12:00 AM
                                         */
                                        let fileName = item.name // Sun Nov 6 07:49:04 2022
                                        let beginSubString = fileName.startIndex
                                        let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                                        let range = beginSubString..<endSubString
                                        let subString = fileName[range]
                                        let stringDescribingDate = String(subString) // Nov 6. 2022 at 12:00 AM
                                        
                                        /*
                                         Hourly measurements accumulate fast, compare the date of the measurement
                                         to the current date, and if they are not equal, delete the measurement.
                                         
                                         A user is still able to view prior dates measurements using the daily, weekly,
                                         and monthly intervals.
                                         
                                         This eliminates a list of >24 measurement files.
                                         */
                                        let measurementDate = self.format_date(stringDescribingDate)
                                        let currentDate = NSDate()
                                        
                                        let currentDay = Calendar.current.dateComponents([.day, .month, .year], from: currentDate as Date)
                                        let measurementDay = Calendar.current.dateComponents([.day, .month, .year], from: measurementDate)
                                        
                                        if (measurementDay == currentDay) { // only show hourly measurements for the current day
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
                                    for item in result.items {
                                        self.dailyItems.append(item)
                                    }
                                }
                                
                            case "weekly":
                                if let result = result {
                                    for item in result.items {
                                        self.weeklyItems.append(item)
                                    }
                                }
                                
                            case "monthly":
                                if let result = result {
                                    for item in result.items {
                                        self.monthlyItems.append(item)
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
