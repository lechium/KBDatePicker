#import "KBDatePickerView.h"

#define STACK_VIEW_HEIGHT 128
DEFINE_ENUM(KBTableViewTag, TABLE_TAG)

@interface UITableView (yep)
- (NSIndexPath *)_focusedCellIndexPath;
@end

@implementation UIView (Helper)

- (void)removeAllSubviews {
    [[self subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

@end

@implementation UIStackView (Helper)

- (void)removeAllArrangedSubviews {
    [[self arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj respondsToSelector:@selector(removeAllArrangedSubviews)]){
            [obj removeAllArrangedSubviews];
        }
        [self removeArrangedSubview:obj];
    }];
}

- (void)setArrangedViews:(NSArray *)views {
    if ([self arrangedSubviews].count > 0){
        [self removeAllArrangedSubviews];
    }
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addArrangedSubview:obj];
    }];
}

@end

@interface KBTableView(){
    NSIndexPath *_selectedIndexPath;
}
@end
@implementation KBTableView //nothing to implement yet, just getting some properties

- (NSIndexPath *)selectedIndexPath {
    return _selectedIndexPath;
}

- (id)valueForIndexPath:(NSIndexPath *)indexPath {
    return [self cellForRowAtIndexPath:indexPath].textLabel.text;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    _selectedIndexPath = selectedIndexPath;
    id value = [self valueForIndexPath:selectedIndexPath];
    if (value){
        //DPLog(@"found cell in %lu", self.tag);
        _selectedValue = value;
        //DPLog(@"selected value set: %@ for index; %lu", _selectedValue, selectedIndexPath.row);
    }
}


@end

@interface KBDatePickerView () {
    NSDate *_currentDate;
    NSArray *_tableViews;
    BOOL _pmSelected;
    NSMutableDictionary *_selectedRowData;
    KBDatePickerMode _datePickerMode;
}

@property (nonatomic, strong) NSArray *hourData;
@property (nonatomic, strong) NSArray *minutesData;
@property (nonatomic, strong) NSArray *dayData;
@property UIStackView *datePickerStackView;
@property KBTableView *monthTable;
@property KBTableView *dayTable;
@property KBTableView *yearTable;
@property KBTableView *hourTable;
@property KBTableView *minuteTable;
@property KBTableView *amPMTable;
@property UILabel *monthLabel;
@property UILabel *dayLabel;
@property UILabel *yearLabel;
@property NSLayoutConstraint *widthConstraint;
@property UILabel *unsupportedLabel;
@end

@implementation KBDatePickerView

- (void)menuGestureRecognized:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        LOG_SELF;
        //[self setPreferredFocusedItem:self.toggleTypeButton]; //PRIVATE_API call, trying to avoid those to stay app store friendly!
        UIApplication *sharedApp = [UIApplication sharedApplication];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIWindow *window = [sharedApp keyWindow];
#pragma clang diagnostic pop
        UIViewController *rootViewController = [window rootViewController];
        if (rootViewController.view == self.superview){
            [rootViewController setNeedsFocusUpdate];
            [rootViewController updateFocusIfNeeded];
        }
    }
}


- (NSDate *)date {
    if (!_currentDate){
        [self setDate:[NSDate date]];
    }
    return _currentDate;
}

- (NSCalendar *)calendar {
    return [NSCalendar currentCalendar];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated {
    _currentDate = date;
    [self scrollToCurrentDateAnimated:animated];
}

- (void)setDate:(NSDate *)date {
    _currentDate = date;
    [self setDate:date animated:true];
}

- (BOOL)isEnabled {
    return FALSE;
}

- (id)init {
    self = [super init];
    _continuous = false;
    _pmSelected = false;
    if (![self date]){
        [self setDate:[NSDate date]];
    }
    UITapGestureRecognizer *menuTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuGestureRecognized:)];
    menuTap.numberOfTapsRequired = 1;
    menuTap.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self addGestureRecognizer:menuTap];
    _selectedRowData = [NSMutableDictionary new];
    _datePickerMode = KBDatePickerModeDate;
    [self layoutViews];
    return self;
}

- (void)layoutForTime {
    
    if (self.hourTable){
        [self.hourTable removeFromSuperview];
        self.hourTable = nil;
        [self.minuteTable removeFromSuperview];
        self.minuteTable = nil;
        [self.amPMTable removeFromSuperview];
        self.amPMTable = nil;
        _tableViews = nil;
    }
    
    [self setupTimeData];
    self.hourTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.hourTable.tag = KBTableViewTagHours;
    self.minuteTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.minuteTable.tag = KBTableViewTagMinutes;
    self.amPMTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.amPMTable.tag = KBTableViewTagAMPM;
    self.hourTable.delegate = self;
    self.hourTable.dataSource = self;
    self.minuteTable.delegate = self;
    self.minuteTable.dataSource = self;
    self.amPMTable.delegate = self;
    self.amPMTable.dataSource = self;
    _tableViews = @[_hourTable, _minuteTable, _amPMTable];
}

- (void)layoutForDate {
    
    if (self.monthLabel){
        [self.monthLabel removeFromSuperview];
        self.monthLabel = nil;
        [self.yearLabel removeFromSuperview];
        self.yearLabel = nil;
        [self.dayLabel removeFromSuperview];
        self.dayLabel = nil;
        self.monthTable = nil;
        self.yearTable = nil;
        self.dayTable = nil;
        _tableViews = nil;
    }
    
    [self populateDaysForCurrentMonth];
    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.monthLabel.text = @"Month";
    self.yearLabel = [[UILabel alloc] init];
    self.yearLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.yearLabel.text = @"Year";
    self.dayLabel = [[UILabel alloc] init];
    self.dayLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.dayLabel.text = @"Day";
    
    self.monthTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.monthTable.tag = KBTableViewTagMonths;
    self.yearTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.yearTable.tag = KBTableViewTagYears;
    self.dayTable = [[KBTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.dayTable.tag = KBTableViewTagDays;
    self.monthTable.delegate = self;
    self.monthTable.dataSource = self;
    self.yearTable.delegate = self;
    self.yearTable.dataSource = self;
    self.dayTable.delegate = self;
    self.dayTable.dataSource = self;
    _tableViews = @[_monthTable, _dayTable, _yearTable];
    [self addSubview:self.monthLabel];
    [self addSubview:self.yearLabel];
    [self addSubview:self.dayLabel];
}

- (void)layoutLabelsForDate {
    [self.monthLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20].active = true;
    [self.dayLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20].active = true;
    [self.dayLabel.centerXAnchor constraintEqualToAnchor:self.dayTable.centerXAnchor].active = true;
    [self.monthLabel.centerXAnchor constraintEqualToAnchor:self.monthTable.centerXAnchor].active = true;
    [self.yearLabel.centerXAnchor constraintEqualToAnchor:self.yearTable.centerXAnchor].active = true;
    [self.yearLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20].active = true;
    [self.monthLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20].active = true;
}

#define MODE_CASE(a) case a: return @"a"

- (char *)stringForMode {
    switch (self.datePickerMode) {
        case KBDatePickerModeDate: return "KBDatePickerModeDate";
        case KBDatePickerModeDateAndTime: return "KBDatePickerModeDateAndTime";
        case KBDatePickerModeCountDownTimer: return "KBDatePickerModeCountDownTimer";
        case KBDatePickerModeTime: return "KBDatePickerModeTime";
    }
    return "Unknown Mode";
}

- (void)layoutUnsupportedView {
    
    if (_datePickerStackView != nil){
        [_datePickerStackView removeAllArrangedSubviews];
        [_datePickerStackView removeFromSuperview];
        _datePickerStackView = nil;
    }
    
    self.unsupportedLabel = [[UILabel alloc] init];
    [self addSubview:self.unsupportedLabel];
    self.unsupportedLabel.translatesAutoresizingMaskIntoConstraints = false;
    [self.unsupportedLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    [self.unsupportedLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    self.unsupportedLabel.text = [self kb_stringWithFormat:"Error: currently '%s' is an unsuppported configuration.", [self stringForMode]];
}

- (void)layoutForDateAndTime {
    [self layoutUnsupportedView];
}

- (void)layoutForCountdownTimer {
    [self layoutUnsupportedView];
}

- (void)layoutLabelsForTime {
    
}

- (void)setupLabelsForMode {
    switch (self.datePickerMode) {
        case KBDatePickerModeTime:
            [self layoutLabelsForTime];
            break;
            
        case KBDatePickerModeDate:
            [self layoutLabelsForDate];
            break;
            
        case KBDatePickerModeDateAndTime:
            [self layoutForDateAndTime];
            break;
            
        case KBDatePickerModeCountDownTimer:
            [self layoutForCountdownTimer];
            break;
            
        default:
            break;
    }
}


- (void)viewSetupForMode {
    
    if (self.unsupportedLabel){
        [self.unsupportedLabel removeFromSuperview];
        self.unsupportedLabel = nil;
    }
    switch (self.datePickerMode) {
        case KBDatePickerModeTime:
            [self layoutForTime];
            break;
            
        case KBDatePickerModeDate:
            [self layoutForDate];
            break;
            
        case KBDatePickerModeDateAndTime:
            [self layoutForDateAndTime];
            break;
            
        case KBDatePickerModeCountDownTimer:
            [self layoutForCountdownTimer];
            break;
            
        default:
            break;
    }
}

- (NSArray *)createNumberArray:(NSInteger)count zeroIndex:(BOOL)zeroIndex leadingZero:(BOOL)leadingZero {
    __block NSMutableArray *_newArray = [NSMutableArray new];
    int startIndex = 1;
    if (zeroIndex){
        startIndex = 0;
    }
    for (int i = startIndex; i < count+startIndex; i++){
        if (leadingZero){
            [_newArray addObject:[NSString stringWithFormat:@"%02i", i]];
        } else {
            [_newArray addObject:[NSString stringWithFormat:@"%i", i]];
        }
    }
    return _newArray;
}
- (NSArray *)monthData {
    return [[self calendar] monthSymbols];
}

- (void)scrollToCurrentDateAnimated:(BOOL)animated {
    
    if (self.datePickerMode == KBDatePickerModeTime){
        [self loadTimeFromDateAnimated:animated];
    } else {
        NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
        NSInteger monthIndex = components.month-1;
        NSString *monthSymbol = self.monthData[monthIndex];
        if (![self.monthTable.selectedValue isEqualToString:monthSymbol]){
            [self scrollToValue:monthSymbol inTableViewType:KBTableViewTagMonths animated:animated];
        }
        NSInteger dayIndex = components.day;
        NSString *dayString = [self kb_stringWithFormat:"%i",dayIndex];
        if (![[_dayTable selectedValue] isEqualToString:dayString]){
            [self scrollToValue:dayString inTableViewType:KBTableViewTagDays animated:animated];
        }
        [_yearTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
        [self delayedUpdateFocus];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _monthTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _dayTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _hourTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _minuteTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _amPMTable){
        return 2;
    } else {
        return 7;
    }
}

- (void)updateDetailsIfContinuous:(NSIndexPath *)indexPath inTable:(KBTableView *)tableView {
    if (!self.continuous){
        return;
    }
    LOG_SELF;
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear fromDate:self.date];
    NSArray *dataSource = nil;
    NSInteger normalizedIndex = NSNotFound;
    if (tableView == _monthTable){
        dataSource = self.monthData;
        normalizedIndex = indexPath.row % dataSource.count;
        NSString *s = [dataSource objectAtIndex: normalizedIndex];
        DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, s);
        components.month = normalizedIndex + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _dayTable){
        dataSource = self.dayData;
        normalizedIndex = indexPath.row % dataSource.count;
        NSString *s = [dataSource objectAtIndex: normalizedIndex];
        DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, s);
        components.day = normalizedIndex + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _minuteTable){
        dataSource = self.minutesData;
        normalizedIndex = indexPath.row % dataSource.count;
        NSString *s = [dataSource objectAtIndex: normalizedIndex];
        DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, s);
        components.minute = normalizedIndex + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _hourTable){
        dataSource = self.hourData;
        normalizedIndex = indexPath.row % dataSource.count;
        NSString *s = [dataSource objectAtIndex: normalizedIndex];
        DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, s);
        components.hour = normalizedIndex + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _yearTable){
        NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.date];
        DPLog(@"year: %lu", year);
        components.year = year + 1;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != components.month));
        _currentDate = newDate;
    }
    if (self.itemSelectedBlock){
           self.itemSelectedBlock(self.date);
       }
       [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)selectMonthAtIndex:(NSInteger)index {
    NSDateComponents *comp = [[self calendar] components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear fromDate:self.date];
    NSInteger adjustedIndex = index;
    if (index > self.monthData.count){
        adjustedIndex = index % self.monthData.count;
    }
    comp.month = adjustedIndex;
    [self setDate:[[self calendar] dateFromComponents:comp]];
    
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        
        NSIndexPath *ip = context.nextFocusedIndexPath;
        KBTableView *table = (KBTableView *)tableView;
        if ([table respondsToSelector:@selector(setSelectedIndexPath:)]){
            if (ip != nil){
                [self updateDetailsIfContinuous:ip inTable:table];
                DPLog(@"next ip: %lu table: %@", ip.row, NSStringFromKBTableViewTag((KBTableViewTag)tableView.tag));
                if (tableView.tag == KBTableViewTagMonths){
                    DPLog(@"MONTH CHANGED!!");
                    [self populateDaysForCurrentMonth];
                    [self.dayTable reloadData];
                }
                [table setSelectedIndexPath:ip];
            }
        }
        [tableView selectRowAtIndexPath:ip animated:false scrollPosition:UITableViewScrollPositionTop];
        
    } completion:^{
        
    }];
}

- (NSInteger)infiniteNumberOfRowsInSection:(NSInteger)section {
    return NUMBER_OF_CELLS;
}

- (void)populateDaysForCurrentMonth {
    NSDateComponents *comp = [[self calendar] components:NSCalendarUnitMonth fromDate:self.date];
    NSRange days = [[self calendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date];
    DPLog(@"month : %lu days %lu", comp.month, days.length);
    self.dayData = [self createNumberArray:days.length zeroIndex:FALSE leadingZero:FALSE];
    [self.dayTable reloadData];
}

- (void)setupTimeData {
    self.hourData = [self createNumberArray:12 zeroIndex:FALSE leadingZero:FALSE];
    self.minutesData = [self createNumberArray:60 zeroIndex:TRUE leadingZero:TRUE];
}

- (NSInteger)startIndexForHours {
    return 24996;
}

- (NSInteger)startIndexForMinutes {
    return 24000;
}

- (id)kb_stringWithFormat:(const char*) fmt,... {
    va_list args;
    char temp[2048];
    va_start(args, fmt);
    vsprintf(temp, fmt, args);
    va_end(args);
    return [[NSString alloc] initWithUTF8String:temp];
}

- (void)loadTimeFromDateAnimated:(BOOL)animated {
    
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.date];
    NSInteger hour = components.hour;
    NSInteger minutes = components.minute;
    BOOL isPM = (hour >= 12);
    if (isPM){
        hour = hour-12;
        NSIndexPath *amPMIndex = [NSIndexPath indexPathForRow:1 inSection:0];
        [self.amPMTable scrollToRowAtIndexPath:amPMIndex atScrollPosition:UITableViewScrollPositionTop animated:false];
    }
    NSString *hourValue = [self kb_stringWithFormat:"%lu", hour];
    NSString *minuteValue = [self kb_stringWithFormat:"%lu", minutes];
    DPLog(@"hours %@ minutes %@", hourValue, minuteValue);
    if (![[self.hourTable selectedValue] isEqualToString:hourValue]){
        [self scrollToValue:hourValue inTableViewType:KBTableViewTagHours animated:animated];
    }
    if (![[self.minuteTable selectedValue] isEqualToString:minuteValue]){
        [self scrollToValue:minuteValue inTableViewType:KBTableViewTagMinutes animated:animated];
    }
}

- (void)delayedUpdateFocus {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setNeedsFocusUpdate];
        [self updateFocusIfNeeded];
    });
}


- (void)scrollToValue:(id)value inTableViewType:(KBTableViewTag)type animated:(BOOL)animated {
    NSInteger foundIndex = NSNotFound;
    NSIndexPath *ip = nil;
    NSInteger dayCount = self.dayData.count;
    NSInteger relationalIndex = 0;
    CGFloat shiftIndex = 0.0;
    NSString *currentValue = nil;
    switch (type) {
        case KBTableViewTagHours:
            foundIndex = [self.hourData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForHours]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.hourTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
            }
            break;
            
        case KBTableViewTagMinutes:
            foundIndex = [self.minutesData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForMinutes]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.minuteTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [self delayedUpdateFocus];
            }
            break;
            
        case KBTableViewTagMonths:
            //value = "December";
            currentValue = self.monthTable.selectedValue; //March
            relationalIndex = [self.monthData indexOfObject:currentValue]; //2
            foundIndex = [self.monthData indexOfObject:value]; //11
            
            //11 - 2 = 9 : go up 9 indexes
            //2 - 11 = -9 : go back 9 indexes
            if (foundIndex != NSNotFound){
                shiftIndex = foundIndex - relationalIndex;
                if (self.monthTable.selectedIndexPath && currentValue){
                    DPLog(@"current value: %@ relationalIndex: %lu found index: %lu, shift index: %.0f", currentValue, relationalIndex, foundIndex, shiftIndex);
                    ip = [NSIndexPath indexPathForRow:self.monthTable.selectedIndexPath.row+shiftIndex inSection:0];
                } else {
                    ip = [NSIndexPath indexPathForRow:[self startIndexForHours]+foundIndex inSection:0];
                }
                [self.monthTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [_monthTable selectRowAtIndexPath:ip animated:animated scrollPosition:UITableViewScrollPositionTop];
                [self delayedUpdateFocus];
                //[self.monthTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
            }
            break;
            
        case KBTableViewTagDays:
            foundIndex = [self.dayData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self indexForDays:dayCount]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.dayTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [self delayedUpdateFocus];
            }
            
        default:
            break;
    }
}

- (NSInteger)indexForDays:(NSInteger)days {
    switch (days) {
        case 28: return 24976;
        case 29: return 24969;
        case 30: return 24990;
        case 31: return 24986;
    }
    return 25000;
}

- (UITableViewCell *)infiniteCellForTableView:(KBTableView *)tableView atIndexPath:(NSIndexPath *)indexPath dataSource:(NSArray *)dataSource {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    NSString *s = [dataSource objectAtIndex: indexPath.row % dataSource.count];
    [cell.textLabel setText: s];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}


- (UITableViewCell *)amPMCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"amPMCell";
    UITableViewCell *cell = [_amPMTable dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    if (indexPath.row == 0){
        cell.textLabel.text = @"AM";
    } else {
        cell.textLabel.text = @"PM";
    }
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (tableView == _hourTable){
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.hourData];
    } else if (tableView == _minuteTable) {
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.minutesData];
    } else if (tableView == _amPMTable) {
        return [self amPMCellForRowAtIndexPath:indexPath];
    } else if (tableView == _monthTable) {
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.monthData];
    } else if (tableView == _dayTable){
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.dayData];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"year"];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"year"];
        }
        NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.date];
        cell.textLabel.text = [NSString stringWithFormat:@"%lu", year - 1 + indexPath.row];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    if (tableView == _monthTable){
        
        //NSString *s = [self.monthData objectAtIndex: indexPath.row % self.monthData.count];
        NSInteger adjustedRow = indexPath.row % self.monthData.count;
        NSInteger month = adjustedRow + 1;
        components.month = month;
        NSDate *newDate = nil;
        NSInteger count = 0;
        do {
            DPLog(@"count: %lu", count);
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
            count++;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != month));
        [self setDate:newDate];
        [self populateDaysForCurrentMonth];
        //[[self dayTable] reloadData];
        [[self yearTable] reloadData];
    } else if (tableView == _dayTable){
        NSInteger adjustedRow = indexPath.row % self.dayData.count;
        components.day = adjustedRow + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        if (newDate){
            [self setDate:newDate];
            [[self monthTable] reloadData];
            [[self yearTable] reloadData];
        }
    } else if (tableView == _yearTable){
        NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.date];
        components.year = year - 1 + indexPath.row;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != components.month));
        [self setDate:newDate];
        [[self monthTable] reloadData];
        [[self yearTable] reloadData];
    } else if (tableView == _hourTable){
        
        NSInteger minutes = [[self calendar] component:NSCalendarUnitMinute fromDate:self.date];
        NSInteger hourSelected = [[self.hourData objectAtIndex: indexPath.row % self.hourData.count] integerValue];
        if (_pmSelected){
            hourSelected += 12;
        }
        components.hour = hourSelected;
        components.minute = minutes;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        [self setDate:newDate];
        //DPLog(@"hourSelected: %lu", hourSelected);
    } else if (tableView == _minuteTable){
        NSInteger hours = [[self calendar] component:NSCalendarUnitHour fromDate:self.date];
        NSString *minuteSelected = [self.minutesData objectAtIndex: indexPath.row % self.minutesData.count];
        components.minute = minuteSelected.integerValue;
        components.hour = hours;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        [self setDate:newDate];
        //DPLog(@"minuteSelected: %@", minuteSelected);
    } else if (tableView == _amPMTable){
        if (indexPath.row == 0){
            //DPLog(@"AM SELECTED");
            _pmSelected = false;
        } else {
            //DPLog(@"PM SELECTED");
            _pmSelected = true;
        }
    }
    
    [self selectionOccured];
}

- (void)selectionOccured {
    if (self.itemSelectedBlock){
        self.itemSelectedBlock(self.date);
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (id)valueForTableViewSelectedCell:(KBTableView *)tableView {
    id data = nil;
    if (!tableView.selectedIndexPath){
        return data;
    }
    switch (tableView.tag) {
        case KBTableViewTagMinutes:
            data = [self.minutesData objectAtIndex: tableView.selectedIndexPath.row % self.minutesData.count];
            break;
            
        case KBTableViewTagHours:
            data = [self.hourData objectAtIndex: tableView.selectedIndexPath.row % self.hourData.count];
            break;
            
        case KBTableViewTagMonths:
            data = [self.monthData objectAtIndex:tableView.selectedIndexPath.row % self.monthData.count];
            break;
        default:
            break;
    }
    
    return data;
}

- (KBDatePickerMode)datePickerMode {
    return _datePickerMode;
}

- (void)setDatePickerMode:(KBDatePickerMode)datePickerMode {
    _datePickerMode = datePickerMode;
    [self adaptModeChange];
}

- (void)adaptModeChange {
    [self removeAllSubviews];
    [self layoutViews];
}

- (CGSize)sizeThatFits:(CGSize)size {
    //CGSize sup = [super sizeThatFits:size];
    return CGSizeMake([self widthForMode], STACK_VIEW_HEIGHT+81+60+40);
}

- (CGFloat)widthForMode {
    switch (self.datePickerMode) {
        case KBDatePickerModeDate: return 720;
        case KBDatePickerModeTime: return 500;
        case KBDatePickerModeDateAndTime: return 800;
        case KBDatePickerModeCountDownTimer: return 400;
    }
    return 720;
}

- (void)layoutViews {
    
    [self viewSetupForMode];
    
    if (!_tableViews){
        DPLog(@"we aint got no table views, bail!!");
        return;
    }
    
    if (_datePickerStackView != nil){
        [_datePickerStackView removeAllArrangedSubviews];
        [_datePickerStackView removeFromSuperview];
        _datePickerStackView = nil;
    }
    
    self.datePickerStackView = [[UIStackView alloc] initWithArrangedSubviews:_tableViews];
    self.datePickerStackView.translatesAutoresizingMaskIntoConstraints = false;
    self.datePickerStackView.spacing = 10;
    self.datePickerStackView.axis = UILayoutConstraintAxisHorizontal;
    self.datePickerStackView.alignment = UIStackViewAlignmentFill;
    self.datePickerStackView.distribution = UIStackViewDistributionFillEqually;
    self.widthConstraint = [self.datePickerStackView.widthAnchor constraintEqualToConstant:self.widthForMode];
    self.widthConstraint.active = true;
    [self.datePickerStackView.heightAnchor constraintEqualToConstant:STACK_VIEW_HEIGHT].active = true;
    
    [self addSubview:self.datePickerStackView];
    
    [self.datePickerStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    [self.datePickerStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    //[self.datePickerStackView.topAnchor constraintEqualToAnchor:self.dayLabel.bottomAnchor constant:60].active = true;
    
    [self setupLabelsForMode];
    [self scrollToCurrentDateAnimated:false];
    
    
}

@end
