#import "KBDatePickerView.h"

#define STACK_VIEW_HEIGHT 128

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

@interface KBDatePickerView () {
    NSDate *_currentDate;
    NSArray *_tableViews;
}

@property UIStackView *datePickerStackView;
@property UITableView *monthTable;
@property UITableView *dayTable;
@property UITableView *yearTable;
@property UITableView *hourTable;
@property UITableView *minuteTable;
@property UITableView *amPMTable;
@property UILabel *monthLabel;
@property UILabel *dayLabel;
@property UILabel *yearLabel;

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
    if (![self date]){
        [self setDate:[NSDate date]];
    }
    _datePickerMode = KBDatePickerModeDate;
    [self layoutViews];
    return self;
}

- (void)layoutForTime {
    
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
    
    self.monthTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.yearTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.dayTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
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

- (void)scrollToCurrentDateAnimated:(BOOL)animated {
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    [_monthTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.month-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
    [_dayTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.day-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
    [_yearTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _monthTable){
        return [self calendar].monthSymbols.count;
    } else if (tableView == _dayTable){
        NSRange days = [[self calendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date];
        return days.length;
    } else {
        return 7;
    }
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        
        NSIndexPath *ip = context.nextFocusedIndexPath;
        NSLog(@"[KBDatePicker] next ip: %@", ip);
        [tableView selectRowAtIndexPath:ip animated:false scrollPosition:UITableViewScrollPositionTop];
        
    } completion:^{
        
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (tableView == _monthTable){
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
    } else {
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
    }
    if (self.itemSelectedBlock){
        self.itemSelectedBlock(self.date);
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (CGSize)sizeThatFits:(CGSize)size {
    //CGSize sup = [super sizeThatFits:size];
    return CGSizeMake(720, STACK_VIEW_HEIGHT+81+60+40);
}

- (void)layoutViews {
    
    [self viewSetupForMode];
    
    if (!_tableViews){
        NSLog(@"[KBDatePickerView] we aint got no table views, bail!!");
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
    [self.datePickerStackView.widthAnchor constraintEqualToConstant:720].active = true;
    [self.datePickerStackView.heightAnchor constraintEqualToConstant:STACK_VIEW_HEIGHT].active = true;
    
    [self addSubview:self.datePickerStackView];
    
    [self.datePickerStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    [self.datePickerStackView.topAnchor constraintEqualToAnchor:self.dayLabel.bottomAnchor constant:60].active = true;
    
    [self setupLabelsForMode];
    
    
}

@end
