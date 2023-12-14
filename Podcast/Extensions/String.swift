//
//  String.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import Foundation

extension String {
    func toSecureHTTPS() -> String {
        
        return self.contains("https") ? self : self.replacingOccurrences(of: "http", with: "https")
        
    }
}
