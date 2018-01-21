//
//  OAuthClientSettings.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-20.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack

struct OAuthClientSettings : Decodable, CustomDebugStringConvertible {
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
                DDLogError("Missing '\(plistName)' in bundle '\(bundle)'")
                return nil
        }
        
        let fileURL = URL(fileURLWithPath: path)
        let decoder = PropertyListDecoder()
        
        guard
            let data = try? Data(contentsOf: fileURL),
            let settings = try? decoder.decode(OAuthClientSettings.self, from: data)
            else {
                DDLogError("Failed getting settings out of file '\(fileURL)'")
                return nil
        }
        
        return settings
    }
}

