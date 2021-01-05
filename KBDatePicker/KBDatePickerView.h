#import <UIKit/UIKit.h>
#import "Macros.h"
#define NUMBER_OF_CELLS 100000

#define TABLE_TAG(XX) \
XX(KBTableViewTagMonths, = 501) \
XX(KBTableViewTagDays, )\
XX(KBTableViewTagYears, )\
XX(KBTableViewTagHours, )\
XX(KBTableViewTagMinutes, )\
XX(KBTableViewTagAMPM, )\
XX(KBTableViewTagWeekday, )\
XX(KBTableViewTagCDHours,)\
XX(KBTableViewTagCDMinutes,)\
XX(KBTableViewTagCDSeconds,)
DECLARE_ENUM(KBTableViewTag, TABLE_TAG)

#define PICKER_MODE(XX) \
XX(KBDatePickerModeTime, ) \
XX(KBDatePickerModeDate, ) \
XX(KBDatePickerModeDateAndTime, ) \
XX(KBDatePickerModeCountDownTimer, )
DECLARE_ENUM(KBDatePickerMode, PICKER_MODE)

@interface UIView (Helper)
-(void)removeAllSubviews;
@end

@interface UIStackView (Helper)
- (void)removeAllArrangedSubviews;
- (void)setArrangedViews:(NSArray * _Nonnull )views;
@end

@interface KBTableView: UITableView
@property NSIndexPath * _Nullable selectedIndexPath;
@property CGFloat customWidth;
@property id _Nullable selectedValue;
- (instancetype _Nonnull )initWithTag:(KBTableViewTag)tag delegate:(id _Nonnull )delegate;
- (id _Nullable )valueForIndexPath:(NSIndexPath *_Nonnull)indexPath;
- (NSArray *_Nonnull)visibleValues;
@end

 // Enums are all defined like this to make it easier to convert them to / from string versions of themselves.
 
@interface KBDatePickerView: UIControl <UITableViewDelegate, UITableViewDataSource>

//scaffolding for when i add these
@property (nullable, nonatomic, strong) NSLocale   *locale;   // default is [NSLocale currentLocale]. setting nil returns to default (not used yet)
@property (null_resettable, nonatomic, copy)   NSCalendar *calendar; // default is [NSCalendar currentCalendar]. setting nil returns to default (not used yet)
@property (nullable, nonatomic, strong) NSTimeZone *timeZone; // default is nil. use current time zone or time zone from calendar (not used yet)

@property (nonnull, nonatomic, strong) NSDate *date;
@property (nullable, nonatomic, strong) NSDate *minimumDate;
@property (nullable, nonatomic, strong) NSDate *maximumDate;

@property (nonatomic) NSTimeInterval countDownDuration; // for KBDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59 (86,399 seconds). value being set is div 60 (drops remaining seconds).
@property (nonatomic) NSInteger      minuteInterval;    // display minutes wheel with interval. interval must be evenly divided into 60. default is 1. min is 1, max is 30 (***not used yet***)

@property BOOL showDateLabel;
@property KBDatePickerMode datePickerMode;
@property NSInteger topOffset;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
+(id _Nonnull )todayInYear:(NSInteger)year;
+ (NSDateFormatter * _Nonnull )sharedDateFormatter;
@end

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"[KBDatePickerView] %@ %@", self, NSStringFromSelector(_cmd))
#define DPLog(format, ...) NSLog(@"[KBDatePickerView] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
