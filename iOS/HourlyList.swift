/*
 Created by John Harrington October, 2022
 
 A view displaying all hourly measurements downloaded from Cloud Storage in
 CloudStorage.swift. Note that only hourly measurements taken on the same date
 are displayed, and their label displays a more readable date format. 
 */


import SwiftUI
import FirebaseCore
import FirebaseStorage


struct HourlyList: View {
    @StateObject private var cloudStorage = CloudStorage()
    @State public var chosenFile: String?
    @State var apiResponse: Response?
    @State var showAlert = false
    
    var body: some View {
            List(cloudStorage.hourlyItems, id: \.self) { reference in
                NavigationLink{
                    DataView(chosenFile: reference.fullPath)
                } label: {
                    /*
                     It is necessary to perform some work already performed in CloudStorage.swift
                     in order to display hourly measurement files in a more readable format (see CloudStorage.swift).
                     
                     This is because an hourlyItem is really an array of type StorageReference, defined
                     in the Firebase Storage package, and is not capable of holding an additional member
                     describing the more readable filename.
                     
                     Why is this work still performed in CloudStorage.swift?
                     Because it simplifies the process of determining a measurement (StorageReference)
                     date, and this is necessary to remove old measurements from Cloud Storage.
                     */
                    let fileName = reference.fullPath
                    let beginSubString = fileName.index(fileName.startIndex, offsetBy: 7)
                    let endSubString = fileName.index(fileName.endIndex, offsetBy: -4)
                    let range = beginSubString..<endSubString
                    let subString = fileName[range]
                    let stringDescribingDate = String(subString)
                    
                    Text(self.format_date(stringDescribingDate))
                }
            }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Hourly")
        .onAppear {
            requestAlert()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Air Quality has exceeded WHO guidelines"), message: Text("On \(apiResponse!.time) \(apiResponse!.pollutant) concentration was measured at \(apiResponse!.value) mcg/L"), dismissButton: .default(Text("OK")))
        }
    }
    
    /*
     Provided a string, this function will format that string according to a provided
     timezone and locale. 
     */
    func format_date(_ string: String) -> String {
        let dateAsString = string
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d HH:mm:ss y"
        df.timeZone = TimeZone(identifier: "MST")
        df.locale = Locale(identifier: "en_US_POSIX")
        let date = df.date(from: dateAsString)!
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
    
    func requestAlert() {
        let api = URL(string: "http://ec2-35-160-195-137.us-west-2.compute.amazonaws.com:8080/")
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: api!) { data, response, error in
            if error == nil {
                let decoder = JSONDecoder()
                if let safeData = data {
                    do {
                        let results = try decoder.decode(Response.self, from: safeData)
                        self.apiResponse = results
                        print(results)
                        if apiResponse!.alert == true {
                            showAlert = true
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
        task.resume()
    }
}
