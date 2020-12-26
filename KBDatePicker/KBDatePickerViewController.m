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
    self.datePickerView.itemSelectedBlock = ^(NSDate * _Nullable date) {
      
        NSLog(@"[KBDatePicker] date selected: %@", date);
        self.datePickerLabel.text = date.description;
    };
    
    
    
}

@end
