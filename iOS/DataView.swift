/*
 Created by John Harrington October, 2022
 
 This file is responsible for loading data from a CSV file downloaded from Cloud Storage.
 This data is used to construct a plot describing air quality measurements across time using Swift Charts. 
 */


import SwiftUI
import FirebaseCore
import FirebaseStorage
import Charts

struct DataView: View {
    let storage = Storage.storage()
    @State public var measurements = [Measurement]() // holds all measurements present in the chosen file
    let chosenFile: String // reference to the file that the user tapped
    
    // API Response and alert handling
    @State var apiResponse: Response?
    @State var showAlert = false
    
    
    func downloadFile(filePath: String) {
        measurements = [Measurement]()
        let ref = storage.reference(forURL: "\(Secrets.StorageBucket)\(chosenFile)")
        var localURL: URL?
        
        do { // create local download url
            let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            localURL = documentURL.appendingPathComponent(chosenFile)
        } catch {
            print("Error generating local download URL")
            return
        }
        
        if let safeURL = localURL { // download chosen file
            _ = ref.write(toFile: safeURL) { url, error in
                if let error = error {
                    print(error)
                    return
                } else {
                    let raw_measurements = parseCSV(safeURL)
                    for each in raw_measurements {
                        let measurement: [String] = each.components(separatedBy: ",")
                        
                        // final row contains nothing, skip this row
                        guard (measurement.count == 3) else {
                            return
                        }
                        
                        measurements.append(Measurement(id: format_date(measurement[2]), type: measurement[0], measurement: Float(measurement[1]) ?? 0.0))
                    }
                }
            }
        }
    }
    
    func format_date(_ string: String) -> Date {
        let dateAsString = string
        let df = DateFormatter()
        df.dateFormat = "EEE MMM d HH:mm:ss y "
        df.timeZone = TimeZone(identifier: "MST")
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: dateAsString)!
    }
    
    func parseCSV(_ url: URL) -> Array<String> {
        do {
            let content = try String(contentsOf: url)
            let parsedCSV: [String] = content.components(separatedBy: "\n")
            return parsedCSV
        }
        catch {
            print("Error parsing CSV")
            return []
        }
    }
    
    func requestAlert() {
        let api = URL(string: Secrets.AlertAPI)
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
    
    var body: some View {
        VStack {
            Text(chosenFile)
            Spacer()
            Chart(measurements){
                LineMark (
                    x: .value("Time", $0.id),
                    y: .value("Measurement", $0.measurement)
                )
                .foregroundStyle(by: .value("Measurement Type", $0.type))
            }
            .chartLegend(position: .top, alignment: .center)
        }
        .onAppear {
            downloadFile(filePath: chosenFile)
            requestAlert()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Air Quality has exceeded WHO guidelines"), message: Text("On \(apiResponse!.time) \(apiResponse!.pollutant) concentration was measured at \(apiResponse!.value) mcg/L"), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
}
