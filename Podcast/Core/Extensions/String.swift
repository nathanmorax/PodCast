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
    
    /// Quita tags HTML y decodifica entidades (&amp;, &nbsp;, etc.)
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        if let attributed = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self
    }

    /// Cheap HTML → text that keeps line breaks (one line per <p>/<br>/<li>),
    /// so "00:00 Intro" lines stay separate. Unlike `strippingHTML()` it doesn't
    /// use NSAttributedString, so it's fast and safe off the main thread.
    func plainTextFromHTML() -> String {
        var text = self
        for tag in ["<br>", "<br/>", "<br />", "</p>", "</li>", "</div>", "</h1>", "</h2>", "</h3>"] {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&nbsp;": " ", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&ndash;": "–", "&mdash;": "—"]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
