//
//  UIView+CornerRadius.swift
//  Podcast
//

import UIKit

extension UIView {
    
    var cornerRadius: Void {
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
