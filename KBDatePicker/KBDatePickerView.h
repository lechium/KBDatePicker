#import <UIKit/UIKit.h>

@interface KBDatePickerView: UIView <UITableViewDelegate, UITableViewDataSource>
@property NSDate * _Nonnull currentDate;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
@end
