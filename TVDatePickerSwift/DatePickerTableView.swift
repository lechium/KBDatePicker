//
//  KBTableView.swift
//  TVDatePickerSwift
//
//  Created by kevinbradley on 9/2/21.
//  Copyright © 2021 nito. All rights reserved.
//

import UIKit
import Foundation

protocol TableViewProtocol: UITableViewDelegate, UITableViewDataSource {
 
}

enum TableViewTag: Int {
    case Months
    case Days
    case Years
    case Hours
    case Minutes
    case AMPM
    case Weekday
    case CDHours
    case CDMinutes
    case CDSeconds
}

class DatePickerTableView: UITableView {
    
    var selectedValue: String?
    var selectedIndexPath: IndexPath? {
        didSet {
            let val = valueFor(indexPath: selectedIndexPath!)
            if val != nil {
                selectedValue = val
            }
        }
    }
    var viewTag: TableViewTag
    var customWidth: CGFloat = 0
    init(tag: TableViewTag, delegate: TableViewProtocol) {
        viewTag = tag
        super.init(frame: .zero, style: .plain)
        dataSource = delegate
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        var og = super.intrinsicContentSize
        if customWidth > 0 {
            og.width = customWidth
        }
        return og
    }
    
    func valueFor(indexPath: IndexPath) -> String? {
        return cellForRow(at: indexPath)?.textLabel?.text
    }
    
    override var description: String {
        let og = super.description
        return "\(og) \(viewTag)"
    }
}
