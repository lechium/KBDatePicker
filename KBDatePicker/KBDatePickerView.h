#import <UIKit/UIKit.h>
#import "Macros.h"
#define NUMBER_OF_CELLS 100000

@interface UIView (Helper)
-(void)removeAllSubviews;
@end

@interface UIStackView (Helper)
- (void)removeAllArrangedSubviews;
- (void)setArrangedViews:(NSArray * _Nonnull )views;
@end

@interface KBTableView: UITableView
@property NSIndexPath * _Nullable selectedIndexPath;
@property id _Nullable selectedValue;
- (id _Nullable )valueForIndexPath:(NSIndexPath *_Nonnull)indexPath;
@end

 // Enums are all defined like this to make it easier to convert them to / from string versions of themselves.
 
#define TABLE_TAG(XX) \
XX(KBTableViewTagMonths, = 501) \
XX(KBTableViewTagDays, )\
XX(KBTableViewTagYears, )\
XX(KBTableViewTagHours, )\
XX(KBTableViewTagMinutes, )\
XX(KBTableViewTagAMPM, )\
XX(KBTaleViewWeekday, )
DECLARE_ENUM(KBTableViewTag, TABLE_TAG)

#define PICKER_MODE(XX) \
XX(KBDatePickerModeTime, ) \
XX(KBDatePickerModeDate, ) \
XX(KBDatePickerModeDateAndTime, ) \
XX(KBDatePickerModeCountDownTimer, )
DECLARE_ENUM(KBDatePickerMode, PICKER_MODE)

@interface KBDatePickerView: UIControl <UITableViewDelegate, UITableViewDataSource>
@property (nonnull, nonatomic, strong) NSDate *date;
@property (nullable, nonatomic, strong) NSDate *minimumDate;
@property (nullable, nonatomic, strong) NSDate *maximumDate;
@property KBDatePickerMode datePickerMode;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
@property BOOL continuous; //whether or not the date is immediately updated as soon as items are scrolled
@end

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"[KBDatePickerView] %@ %@", self, NSStringFromSelector(_cmd))
#define DPLog(format, ...) NSLog(@"[KBDatePickerView] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
