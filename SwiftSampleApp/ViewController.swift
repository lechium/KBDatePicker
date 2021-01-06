//
//  ViewController.swift
//  SwiftSampleApp
//
//  Created by Kevin Bradley on 1/6/21.
//  Copyright © 2021 nito. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let datePickerView = KBDatePickerView()
    let toggleButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        datePickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePickerView)
        datePickerView.showDateLabel = true
        datePickerView.addTarget(self, action: #selector(actionOccured(sender:)), for: .valueChanged)
        datePickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        datePickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        toggleButton.setTitle("Toggle", for: .normal)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleButton)
        toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        toggleButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        toggleButton.addTarget(self, action: #selector(toggleMode), for: .primaryActionTriggered)
        
    }
   
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [toggleButton]
    }
    
    @objc func toggleMode() -> Void {
        if datePickerView.datePickerMode == KBDatePickerModeCountDownTimer {
            self.datePickerView.datePickerMode = KBDatePickerModeTime
        } else {
            self.datePickerView.datePickerMode = KBDatePickerMode(rawValue: self.datePickerView.datePickerMode.rawValue+1)
        }
    }
    
    @objc func actionOccured(sender: KBDatePickerView) -> Void {
        print("date selected: \(sender.date)")
    }

}

