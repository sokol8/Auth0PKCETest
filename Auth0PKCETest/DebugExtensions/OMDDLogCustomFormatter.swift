//
//  OMDDLogCustomFormatter.swift
//  Auth0PKCETest
//
//  Created by Kostiantyn Sokolinskyi on 2018-01-21.
//  Copyright © 2018 Omni Mobile Works Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack

class OMDDLogCustomFormatter : NSObject, DDLogFormatter {
    
    let dateFormatter = DateFormatter()
    
    public override init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        super.init()
    }
    
    func format(message logMessage: DDLogMessage) -> String? {
        let logLevel : String = {
            switch logMessage.flag {
                case .error     : return "❌"
                case .warning   : return "🔶"
                case .info      : return "🔷"
                case .debug     : return "◾️"
                default         : return "◽️"
            }
        }()
        
        let dateAndTime = dateFormatter.string(from: logMessage.timestamp)
        let formattedMessage = "\(logLevel) \(dateAndTime) [\(logMessage.threadID):\(logMessage.queueLabel)] | \(logMessage.message) (\(logMessage.fileName):\(logMessage.line))"
        
        return formattedMessage
    }
}
