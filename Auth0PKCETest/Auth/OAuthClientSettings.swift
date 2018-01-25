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
    
    var OAuthBaseURL: String
    var authorizationCodePath : String
    var accessTokenPath : String
    
    var redirectUri: String
    var audience: String
    var scope: String
    var responseType: String
    var clientId: String
    var codeChallengeMethod: String
    var codeVerifier: String?
    var codeChallenge: String?
    var grantType: String
    var authorizationCode: String?
    
    // TODO: move to ENUM
    static let URLQueryItemKeysMapping = [ "redirectUri"           : "redirect_uri",
                                    "audience"              : "audience",
                                    "scope"                 : "scope",
                                    "responseType"          : "response_type",
                                    "clientId"              : "client_id",
                                    "codeChallengeMethod"   : "code_challenge_method",
                                    "codeChallenge"         : "code_challenge",
                                    "codeVerifier"          : "code_verifier",
                                    "grantType"             : "grant_type",
                                    "authorizationCode"     : "code"]
    
//    enum URLQueryItemKeys: String {
//        case redirectUri = "redirect_uri"
//        case audience
//        case scope
//        case responseType = "response_type"
//        case clientId = "client_id"
//        case codeChallenge = "code_challenge"
//        case codeChallengeMethod = "code_challenge_method"
//        case codeVerifier = "code_verifier"
//    }
}

extension OAuthClientSettings {
    
    init?(withBundle bundle: Bundle, plistName: String) {
        guard let path = bundle.path(forResource: plistName, ofType: "plist")
            else {
                DDLogError("Missing '\(plistName)' in bundle '\(bundle)'")
                return nil
        }
        
        let fileURL = URL(fileURLWithPath: path)
        let decoder = PropertyListDecoder()
        
        guard
            let data = try? Data(contentsOf: fileURL)
            else {
                DDLogError("Failed reading the file '\(fileURL)'")
                return nil
        }
        
        do {
            self = try decoder.decode(OAuthClientSettings.self, from: data)
        }
        catch {
            DDLogError("Failed parsing data out of file '\(fileURL)'")
            return nil
        }
    }
}

