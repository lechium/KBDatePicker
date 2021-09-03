//
//  ViewController.swift
//  SwiftSampleApp
//
//  Created by Kevin Bradley on 1/6/21.
//  Copyright © 2021 nito. All rights reserved.
//

import UIKit
import TVDatePickerSwift

class ViewController: UIViewController {
    
    let datePickerView = DatePickerView(withHybrdidLayout: false)
    //let datePickerView = KBDatePickerView()
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
        
        datePickerView.datePickerMode = .CountDownTimer//KBDatePickerModeCountDownTimer
        datePickerView.countDownDuration = 4100
    }
   
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [toggleButton]
    }
    
    @objc func toggleMode() -> Void {
        if datePickerView.datePickerMode == .CountDownTimer {
            self.datePickerView.datePickerMode = .Time
        } else {
            //self.datePickerView.datePickerMode = DatePickerMode(rawValue:)//datePickerView.datePickerMode. //KBDatePickerMode(rawValue: self.datePickerView.datePickerMode.rawValue+1)
        }
    }
    
    @objc func actionOccured(sender: DatePickerView) -> Void {
        //print
        print("date selected: \(sender.date)")
    }

}

