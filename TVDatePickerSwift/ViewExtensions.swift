//
//  UIView+Extensions.swift
//  TVDatePickerSwift
//
//  Created by kevinbradley on 9/2/21.
//  Copyright © 2021 nito. All rights reserved.
//

import UIKit
import Foundation

extension UIStackView {
    
    @objc func removeAllArrangedSubviews() {
        for view in arrangedSubviews {
            let sel = NSSelectorFromString("removeAllArrangedSubviews")
            if view.responds(to: sel) {
                view.perform(sel)
            }
            removeArrangedSubview(view)
        }
    }
    
    @objc func setArrangedSubviews(_ views: [UIView]) {
        if arrangedSubviews.count > 0 {
            removeAllArrangedSubviews()
        }
        for view in views {
            addArrangedSubview(view)
        }
    }
}

extension UIView {
    @objc func removeAllSubviews() {
        for view in subviews {
            let sel = NSSelectorFromString("removeAllArrangedSubviews")
            if view.responds(to: sel) {
                view.perform(sel)
            }
            view.removeFromSuperview()
        }
    }
}
