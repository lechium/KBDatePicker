#import "KBDatePickerView.h"

#define STACK_VIEW_HEIGHT 128

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
        DPLog(@"found cell in %lu", self.tag);
        _selectedValue = value;
        DPLog(@"selected value set: %@ for index; %lu", _selectedValue, selectedIndexPath.row);
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
@end

@implementation KBDatePickerView

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
    _pmSelected = false;
    if (![self date]){
        [self setDate:[NSDate date]];
    }
    _selectedRowData = [NSMutableDictionary new];
    _datePickerMode = KBDatePickerModeTime;
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


- (void)layoutForDateAndTime {
    
}

- (void)layoutForCountdownTimer {
    
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
    return @[@"January", @"Februrary", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"];
}

- (void)scrollToCurrentDateAnimated:(BOOL)animated {
    
    if (self.datePickerMode == KBDatePickerModeTime){
        [self loadTimeFromDateAnimated:animated];
    } else {
        NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
        [_monthTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.month-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
        [_dayTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.day-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
        [_yearTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _monthTable){
        return [self calendar].monthSymbols.count;
    } else if (tableView == _dayTable){
        NSRange days = [[self calendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date];
        return days.length;
    } else if (tableView == _hourTable){
        return [self hourNumberOfRowsInSection:section];
    } else if (tableView == _minuteTable){
        return [self hourNumberOfRowsInSection:section];
    } else if (tableView == _amPMTable){
        return 2;
    } else {
        return 7;
    }
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        
        NSIndexPath *ip = context.nextFocusedIndexPath;
        DPLog(@"next ip: %@", ip);
        KBTableView *table = (KBTableView *)tableView;
        if ([table respondsToSelector:@selector(setSelectedIndexPath:)]){
            if (ip != nil){
                [table setSelectedIndexPath:ip];
            }
        }
        [tableView selectRowAtIndexPath:ip animated:false scrollPosition:UITableViewScrollPositionTop];
        
    } completion:^{
        
    }];
}

- (NSInteger)hourNumberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return NUMBER_OF_CELLS;
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
    
    LOG_SELF;
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
    [self scrollToValue:hourValue inTableViewType:KBTableViewTagHours animated:animated];
    [self scrollToValue:minuteValue inTableViewType:KBTableViewTagMinutes animated:animated];
    
    
}

- (void)scrollToValue:(id)value inTableViewType:(KBTableViewTag)type animated:(BOOL)animated {
    NSInteger foundIndex = NSNotFound;
    NSIndexPath *ip = nil;
    switch (type) {
        case KBTableViewTagHours:
            foundIndex = [self.hourData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForHours]+foundIndex inSection:0];
                DPLog(@"found index: %@", ip);
                [self.hourTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
            }
            break;
            
        case KBTableViewTagMinutes:
            foundIndex = [self.minutesData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForMinutes]+foundIndex inSection:0];
                DPLog(@"found index: %@", ip);
                [self.minuteTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
            }
            break;
            
        default:
            break;
    }
}

- (UITableViewCell *)minutesCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"minutesCell";
    UITableViewCell *cell = [_minuteTable dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    NSString *s = [self.minutesData objectAtIndex: indexPath.row % self.minutesData.count];
    [cell.textLabel setText: s];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (UITableViewCell *)hourCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"hoursCell";
    UITableViewCell *cell = [_hourTable dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    NSString *s = [self.hourData objectAtIndex: indexPath.row % self.hourData.count];
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
        return [self hourCellForRowAtIndexPath:indexPath];
    } else if (tableView == _minuteTable) {
        return [self minutesCellForRowAtIndexPath:indexPath];
    } else if (tableView == _amPMTable) {
        return [self amPMCellForRowAtIndexPath:indexPath];
    } else if (tableView == _monthTable) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"month"];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"month"];
        }
        cell.textLabel.text = [[self calendar] monthSymbols][indexPath.row];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else if (tableView == _dayTable){
        cell = [tableView dequeueReusableCellWithIdentifier:@"day"];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"day"];
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%lu", indexPath.row + 1];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
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

- (NSInteger)currentHoursIfApplicable {
    if (self.datePickerMode == KBDatePickerModeTime){
        NSIndexPath *indexPath = [_hourTable _focusedCellIndexPath];
        NSString *s = [self.hourData objectAtIndex: indexPath.row % self.hourData.count];
        return s.integerValue;
    }
    return 0;
}

- (NSInteger)currentMinutesIfApplicable {
    if (self.datePickerMode == KBDatePickerModeTime){
        NSIndexPath *indexPath = [_minuteTable _focusedCellIndexPath];
        NSString *s = [self.minutesData objectAtIndex: indexPath.row % self.minutesData.count];
        return s.integerValue;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    if (tableView == _monthTable){
        NSInteger month = indexPath.row + 1;
        components.month = month;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != month));
        [self setDate:newDate];
        [[self dayTable] reloadData];
        [[self yearTable] reloadData];
    } else if (tableView == _dayTable){
        components.day = indexPath.row + 1;
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
        DPLog(@"hourSelected: %lu", hourSelected);
    } else if (tableView == _minuteTable){
        NSInteger hours = [[self calendar] component:NSCalendarUnitHour fromDate:self.date];
        NSString *minuteSelected = [self.minutesData objectAtIndex: indexPath.row % self.minutesData.count];
        components.minute = minuteSelected.integerValue;
        components.hour = hours;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        [self setDate:newDate];
        DPLog(@"minuteSelected: %@", minuteSelected);
    } else if (tableView == _amPMTable){
        if (indexPath.row == 0){
            DPLog(@"AM SELECTED");
            _pmSelected = false;
        } else {
            DPLog(@"PM SELECTED");
            _pmSelected = true;
        }
    }
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [self scrollToCurrentDateAnimated:true];
    });

}

@end
