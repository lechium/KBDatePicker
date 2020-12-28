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
@end

@implementation KBDatePickerViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self scrollToCurrentDateAnimated:true];
}

- (void)toggleMode {
    if (self.datePickerView.datePickerMode == KBDatePickerModeTime){
        [self.datePickerView setDatePickerMode:KBDatePickerModeDate];
    } else {
        [self.datePickerView setDatePickerMode:KBDatePickerModeTime];
    }
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
    [self.datePickerView.widthAnchor constraintEqualToConstant:720].active = true;
    [self.datePickerView.heightAnchor constraintEqualToConstant:128+81+60+40].active = true;
    __weak typeof(self) weakSelf = self;
    self.datePickerView.itemSelectedBlock = ^(NSDate * _Nullable date) {
        NSLog(@"[KBDatePicker] date selected: %@", date);
        weakSelf.datePickerLabel.text = date.description;
    };
    
    UIButton *toggleTypeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    toggleTypeButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:toggleTypeButton];
    [toggleTypeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    [toggleTypeButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40].active = true;
    [toggleTypeButton setTitle:@"Toggle" forState:UIControlStateNormal];
    [toggleTypeButton.heightAnchor constraintEqualToConstant:60].active = true;
    [toggleTypeButton.widthAnchor constraintEqualToConstant:200].active = true;
    [toggleTypeButton addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventPrimaryActionTriggered];
     
    [self.datePickerView addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)datePickerChanged:(KBDatePickerView *)dpv {
    NSLog(@"[KBDatePicker] changed: %@", dpv.date);
}

@end
