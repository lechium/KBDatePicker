//
//  KBDatePickerViewController.h
//  KBDatePicker
//
//  Created by Kevin Bradley on 12/26/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KBDatePickerView: UIView <UITableViewDelegate, UITableViewDataSource>
@property NSDate *currentDate;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
@end

@interface KBDatePickerViewController : UIViewController
@end

