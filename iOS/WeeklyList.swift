/*
 Created by John Harrington October, 2022
 
 A view displaying all weekly measurements downloaded from Cloud Storage in
 CloudStorage.swift.
 */


import SwiftUI
import FirebaseCore
import FirebaseStorage


struct WeeklyList: View {
    @StateObject private var cloudStorage = CloudStorage()
    @State public var chosenFile: String?
    @State var apiResponse: Response?
    @State var showAlert = false
    
    var body: some View {
            List(cloudStorage.weeklyItems, id: \.self) { reference in
                NavigationLink{
                    DataView(chosenFile: reference.fullPath)
                } label: {
                    /*
                     Display the measurement time information in a more readable format
                     by eliminating the year and file extension.
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
        .navigationTitle("Weekly")
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
