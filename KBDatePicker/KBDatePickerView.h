#import <UIKit/UIKit.h>

#define NUMBER_OF_CELLS 100000

@interface UIStackView (Helper)
- (void)removeAllArrangedSubviews;
- (void)setArrangedViews:(NSArray *)views;
@end


typedef NS_ENUM(NSInteger, KBDatePickerMode) {
    KBDatePickerModeTime,           // Displays hour, minute, and optionally AM/PM designation depending on the locale setting (e.g. 6 | 53 | PM)
    KBDatePickerModeDate,           // Displays month, day, and year depending on the locale setting (e.g. November | 15 | 2007)
    KBDatePickerModeDateAndTime,    // Displays date, hour, minute, and optionally AM/PM designation depending on the locale setting (e.g. Wed Nov 15 | 6 | 53 | PM)
    KBDatePickerModeCountDownTimer, // Displays hour and minute (e.g. 1 | 53)
};

@interface KBDatePickerView: UIControl <UITableViewDelegate, UITableViewDataSource>
@property NSDate * _Nonnull date;
@property KBDatePickerMode datePickerMode;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);

@end
