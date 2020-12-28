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

#define TABLE_TAG(XX) \
XX(KBTableViewTagMonths, = 501) \
XX(KBTableViewTagDays, )\
XX(KBTableViewTagYears, )\
XX(KBTableViewTagHours, )\
XX(KBTableViewTagMinutes, )\
XX(KBTableViewTagAMPM, )\
XX(KBTaleViewWeekday, )
DECLARE_ENUM(KBTableViewTag, TABLE_TAG)

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
@property BOOL continuous; //whether or not the date is immediately updated as soon as items are scrolled
@end

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"[KBDatePickerView] %@ %@", self, NSStringFromSelector(_cmd))
#define DPLog(format, ...) NSLog(@"[KBDatePickerView] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
