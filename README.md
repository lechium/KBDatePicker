# KBDatePicker
UIDatePicker for tvOS! ported from https://github.com/jruhym/datePicker

This has seen a long road of being a POC from the code listed above, to written completely in obj-c, to being re-written in Swift! There are now two versions that parallel in functionality one in Objective-C and one in Swift (the swift target is a framework you can embed too!) Will updated README with swift sample code and info later, however, the Swift sample app now uses the new Swift framework.

all 4 date picker modes are supported:

Objective-C:

```Objective-C
 KBDatePickerModeTime
 KBDatePickerModeDate
 KBDatePickerModeDateAndTime
 KBDatePickerModeCountDownTimer
```

Swift:

```Swift
 DatePickerMode.Time
 DatePickerMode.Date
 DatePickerMode.DateAndTime
 DatePickerMode.CountDownTimer
```
4 of the most important properties are supported

- (NSDate *)date
- (NSDate *)minimumDate *
- (NSDate *)maximumDate *
- (NSTimeInterval)countDownDuration *

***minimum(maximum)Date aren't supported in KBDatePickerModeDateAndTime/DatePickerMode.DateAndTime mode yet***

## Usage

In the near future I will try to make this work w/ CocoaPods and Carthage, for now just grab the KBDatePicker/KBDatePicker folder (with KBDatePickerView.h/m and Macros.h in it) and
add that to your project.

Adding the control & listening for control events is the same as any other UIControl (same as UI*Picker* iOS counterparts)

Objective-C:

```Objective-C

#import "KBDatePickerView.h"

- (void)addDatePicker {
    KBDatePickerView *datePickerView = [KBDatePickerView new];
    datePickerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:datePickerView];
    
    //would center the view obviously optional!
    [datePickerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = true;
    [datePickerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    
    //listen for changes
    [datePickerView addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
    
    //use a countdown timer instead
    [datePickerView setDatePickerMode:KBDatePickerModeCountDownTimer];
    [datePickerView setCountDownDuration:4205];
    
}

- (void)datePickerChanged:(KBDatePickerView *)dpv {
    NSLog(@"[KBDatePicker] changed: %@", dpv.date);
    if (dpv.datePickerMode == KBDatePickerModeCountDownTimer){
        NSString *time = [NSString stringWithFormat:@"countdown duration: %.0f seconds", dpv.countDownDuration];
        self.datePickerLabel.text = time;
    } else {
        NSDateFormatter *dateFormatter = [KBDatePickerView sharedDateFormatter];
        NSString *strDate = [dateFormatter stringFromDate:dpv.date];
        NSLog(@"strDate: %@", strDate); // Result: strDate: 2014/05/19 10:51:50
        self.datePickerLabel.text = strDate;
    }
    
}

```

Swift:

```Swift

import UIKit
import TVDatePickerSwift

class ViewController: UIViewController {
    
    let datePickerView = DatePickerView(withHybrdidLayout: false)
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
        
        datePickerView.datePickerMode = .CountDownTimer
        //datePickerView.countDownDuration = 4100
        datePickerView.minuteInterval = 6
    }
   
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [toggleButton]
    }
    
    @objc func toggleMode() -> Void {
        if datePickerView.datePickerMode == .CountDownTimer {
            self.datePickerView.datePickerMode = .Time
        } else {
            self.datePickerView.datePickerMode = DatePickerMode(rawValue: self.datePickerView.datePickerMode.rawValue+1)!
        }
    }
    
    @objc func actionOccured(sender: DatePickerView) -> Void {
        //print
        print("date selected: \(sender.date)")
    }
}

```

There are both Objective-C and Swift sample apps included in this project. Please refer to them if this sample code isnt sufficient!

## Troubleshooting

Sometimes you may have trouble directing the focus engine on and off of KBDatePicker, if this happens, i recommend creating focus guides similar to the ones created in the sample project. This sample below is assuming theres a toggle button like the one in the sample app and isnt code that will run on its own without substituting in the view you want the focus engine to redirect to.

```Objective-C

    UIFocusGuide *focusGuideLeft = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:focusGuideLeft];
    [focusGuideLeft.topAnchor constraintEqualToAnchor:self.datePickerView.topAnchor].active = true;
    [focusGuideLeft.bottomAnchor constraintEqualToAnchor:self.datePickerView.bottomAnchor].active = true;
    [focusGuideLeft.widthAnchor constraintEqualToConstant:40].active = true;
    [focusGuideLeft.rightAnchor constraintEqualToAnchor:self.datePickerView.leftAnchor].active = true;
    focusGuideLeft.preferredFocusEnvironments = @[self.toggleTypeButton];
    
    UIFocusGuide *focusGuideRight = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:focusGuideRight];
    [focusGuideRight.topAnchor constraintEqualToAnchor:self.datePickerView.topAnchor].active = true;
    [focusGuideRight.bottomAnchor constraintEqualToAnchor:self.datePickerView.bottomAnchor].active = true;
    [focusGuideRight.leftAnchor constraintEqualToAnchor:self.datePickerView.rightAnchor].active = true;
    [focusGuideRight.widthAnchor constraintEqualToConstant:40].active = true;
    focusGuideRight.preferredFocusEnvironments = @[self.toggleTypeButton];

```

## Road Map / Plans 

- Plan on adding localization support at some point for the text labels that are created for some of the view modes
- Create a CocoaPod & Cartfile (or whatever carthage uses)
- Support min/max date in KBDatePickerModeDateAndTime

## Feature Requests

Feel free to request features if you think i've overlooked anything! 

## In Action

![FLEXing Action](datePickerScience.gif "In Action")
![Sample App](date_picker.gif "In Sample App")

## Screenshots

![FLEXing](FLEX.png "Example embedded in FLEX")
![KBDatePickerModeTime](Examples/KBDatePickerModeTime.png "KBDatePickerModeTime")
![KBDatePickerModeDate](Examples/KBDatePickerModeDate.png "KBDatePickerModeDate")
![KBDatePickerModeDateAndTime](Examples/KBDatePickerModeDateAndTime.png "KBDatePickerModeDateAndTime")
![KBDatePickerModeCountDownTimer](Examples/KBDatePickerModeCountDownTimer.png "KBDatePickerModeCountDownTimer")
