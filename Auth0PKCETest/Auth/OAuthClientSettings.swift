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
    
    enum URLQueryItemKeys: String {
        case redirectUri = "redirect_uri"
        case audience = "audience"
        case scope = "scope"
        case responseType = "response_type"
        case clientId = "client_id"
        case codeChallenge = "code_challenge"
        case codeChallengeMethod = "code_challenge_method"
        case codeVerifier = "code_verifier"
        case grantType = "grant_type"
        case authorizationCode = "code"
    }
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
    
    var urlComponentsQueryItems: [URLQueryItem] {
        let audienceItem = URLQueryItem(name: URLQueryItemKeys.audience.rawValue, value: audience)
        let scopeItem = URLQueryItem(name: URLQueryItemKeys.scope.rawValue, value: scope)
        let responseTypeItem = URLQueryItem(name: URLQueryItemKeys.responseType.rawValue, value: responseType)
        let clientIdItem = URLQueryItem(name: URLQueryItemKeys.clientId.rawValue, value: clientId)
        let codeChallengeItem = URLQueryItem(name: URLQueryItemKeys.codeChallenge.rawValue, value: codeChallenge)
        let codeChallengeMethodItem = URLQueryItem(name: URLQueryItemKeys.codeChallengeMethod.rawValue, value: codeChallengeMethod)
        let redirectUrlItem = URLQueryItem(name: URLQueryItemKeys.redirectUri.rawValue, value: redirectUri)
        
        return [audienceItem, scopeItem, responseTypeItem, clientIdItem, codeChallengeItem, codeChallengeMethodItem, redirectUrlItem]
    }
}

