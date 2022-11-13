/*
 Created by John Harrington October, 2022
 
 A struct describing a HTTP response from the Python/alert.py API.
 */

import Foundation

struct Response: Decodable {
    let alert: Bool
    let pollutant: String
    let time: String
    let value: Float
}

