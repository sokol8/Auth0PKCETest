//
//  OAuthClientSettings.swift
//  Auth0PKCETest
//
//  Created by Tatyana Remayeva on 2018-01-20.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack

struct OAuthClientSettings : Decodable {
    var redirectUri: String
    var audience: String
    var scope: String
    var responseType: String
    var clientId: String
    var codeChallengeMethod: String
    var codeVerifier: String?
    var codeChallenge: String?
    
    static func loadFrom(bundle: Bundle, plistName: String) -> OAuthClientSettings? {
        guard let path = bundle.path(forResource: plistName, ofType: "plist")
            else {
                DDLogError("Missing '\(plistName)' with proper initialisation data in bundle '\(bundle)'")
                return nil
        }
        
        let fileURL = URL(fileURLWithPath: path)
        var settings: OAuthClientSettings?
        if let data = try? Data(contentsOf: fileURL) {
            let decoder = PropertyListDecoder()
            settings = try? decoder.decode(OAuthClientSettings.self, from: data)
        }
        return settings
    }
}
