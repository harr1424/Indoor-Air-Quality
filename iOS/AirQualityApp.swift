/*
 Created by John Harrington October, 2022
 
 This file sets up the Firebase SDKs used in this app (Core and Storage),
 requests the user's permission to display notifications,
 and will attempt to register the user's device with the APNs server (see Go directory).
 */

import SwiftUI
import FirebaseCore
import FirebaseStorage
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        permissionRequest()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func permissionRequest() {
        /*
         Access the user notification center and request permission to send notifications
         */
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print(error)
            }
        }
        
        /*
         Define an action allowing the user to dismiss the air quality alert and add this action
         to an AirQualityNotification Category of notifications.
         */
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "OK", options: [])
        let airQualityNotification = UNNotificationCategory(identifier: "AIR_QUALITY", actions: [dismissAction], intentIdentifiers: [])
        center.setNotificationCategories([airQualityNotification])
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // send token to web server
        let url = URL(string: Secrets.APNsServer)
        
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = ["ID": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Could not serialize device token: \(error.localizedDescription)")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error initiating data task: \(error.localizedDescription)")
                return
            }
            
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (httpResponse.statusCode == 201)
            else {
                print("Invalid response from APNs server")
                return
            }
        }
        task.resume()
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct AirQualityApp: App {
    
    // initialize firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
