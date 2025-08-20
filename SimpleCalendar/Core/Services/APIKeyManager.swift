//
//  APIKeyManager.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/20/25.
//

import Foundation

class APIKeyManager {
    static var geminiAPIKey: String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            print("ERROR: Secrets.plist not found or could not be loaded. Please create one and add your 'GeminiAPIKey'.")
            return ""
        }
        return plist["GeminiAPIKey"] as? String ?? ""
    }
}
