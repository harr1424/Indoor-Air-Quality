/*
 Created by John Harrington October, 2022
 
 A struct describing measurement data retrieved from Cloud Storage. 
 */

import Foundation

struct Measurement: Identifiable {
    var id: Date // time of measurement
    var type: String
    var measurement: Float
}


