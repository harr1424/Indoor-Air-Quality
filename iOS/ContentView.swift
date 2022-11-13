/*
 Created by John Harrington October, 2022
 
 This is the default view for the application. The user is presented with a list
 of measurement intervals (hourly, daily, weekly, and monthly) and upon tapping an
 interval will be shown a list of measurements taken according to that interval. 
 */


import SwiftUI
import FirebaseCore
import FirebaseStorage


struct ContentView: View {
    @State var apiResponse: Response?  // used to hold information received from API (see Python/alert.py)
    @State var showAlert = false  // controls the display of the alert defined in this file
    
    var body: some View {
        NavigationView{
            List {
                NavigationLink{
                    HourlyList()
                } label: {
                    Text("Hourly")
                }
                NavigationLink{
                    DailyList()
                } label: {
                    Text("Daily")
                }
                NavigationLink{
                    WeeklyList()
                } label: {
                    Text("Weekly")
                }
                NavigationLink{
                    MonthlyList()
                } label: {
                    Text("Monthly")
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Measurements")
            .onAppear {
                requestAlert()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Air Quality has exceeded WHO guidelines"), message: Text("On \(apiResponse!.time) \(apiResponse!.pollutant) concentration was measured at \(apiResponse!.value) mcg/L"), dismissButton: .default(Text("OK")))
            }
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
    
}

