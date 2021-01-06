//
//  KBDatePickerViewController.m
//  KBDatePicker
//
//  Created by Kevin Bradley on 12/26/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "KBDatePickerViewController.h"
#import "KBDatePickerView.h"
@interface KBDatePickerViewController() {
    
}
@property KBDatePickerView *datePickerView;
@property UILabel *datePickerLabel;
@property UIButton *toggleTypeButton;
@end


@implementation KBDatePickerViewController

- (NSArray *)preferredFocusEnvironments {
    if (self.toggleTypeButton){
        return @[self.toggleTypeButton];
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.datePickerView = [KBDatePickerView new];
    self.datePickerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.datePickerView];
    self.datePickerLabel = [[UILabel alloc] init];
    self.datePickerLabel.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.datePickerLabel];
    [self.datePickerLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [self.datePickerLabel.bottomAnchor constraintEqualToAnchor:self.datePickerView.topAnchor constant:-80].active = true;
    [self.datePickerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = true;
    [self.datePickerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    //[self.datePickerView.widthAnchor constraintEqualToConstant:720].active = true;

    self.toggleTypeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleTypeButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.toggleTypeButton];
    [self.toggleTypeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [self.toggleTypeButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40].active = true;
    [self.toggleTypeButton setTitle:@"Toggle" forState:UIControlStateNormal];
    [self.toggleTypeButton.heightAnchor constraintEqualToConstant:60].active = true;
    [self.toggleTypeButton.widthAnchor constraintEqualToConstant:200].active = true;
    [self.toggleTypeButton addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    [self.datePickerView addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
    
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
    
    [self.datePickerView setMinimumDate:[NSDate distantPast]];
    [self.datePickerView setMaximumDate:[NSDate distantFuture]];
    
    //example of doing a count down timer instead
    
    [self.datePickerView setDatePickerMode:KBDatePickerModeCountDownTimer];
    [self.datePickerView setCountDownDuration:4205];
}

- (void)toggleMode {
    if (self.datePickerView.datePickerMode == KBDatePickerModeCountDownTimer){
        [self.datePickerView setDatePickerMode:KBDatePickerModeTime];
    } else {
        [self.datePickerView setDatePickerMode:self.datePickerView.datePickerMode+1];
    }
}

- (void)datePickerChanged:(KBDatePickerView *)dpv {
    NSLog(@"[KBDatePicker] changed: %@", dpv.date);
    if (self.datePickerView.datePickerMode == KBDatePickerModeCountDownTimer){
        NSString *time = [NSString stringWithFormat:@"countdown duration: %.0f seconds", dpv.countDownDuration];
        self.datePickerLabel.text = time;
    } else {
        NSDateFormatter *dateFormatter = [KBDatePickerView sharedDateFormatter];
        NSString *strDate = [dateFormatter stringFromDate:dpv.date];
        NSLog(@"strDate: %@", strDate); // Result: strDate: 2014/05/19 10:51:50
        self.datePickerLabel.text = strDate;
    }
    
}

@end
