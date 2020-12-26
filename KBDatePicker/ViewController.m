//
//  ViewController.m
//  KBDatePicker
//
//  Created by Kevin Bradley on 12/26/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSDate *_currentDate;
}



@property UIStackView *datePickerStackView;
@property UITableView *monthTable;
@property UITableView *dayTable;
@property UITableView *yearTable;
@property UILabel *monthLabel;
@property UILabel *dayLabel;
@property UILabel *yearLabel;

@property UILabel *dateLabel;



@end

@implementation ViewController

- (NSDate *)currentDate {
    if (!_currentDate){
        _currentDate = [NSDate date];
    }
    return _currentDate;
}

- (NSCalendar *)calendar {
    return [NSCalendar currentCalendar];
}

- (void)setCurrentDate:(NSDate *)date {
    _currentDate = date;
    _dateLabel.text = date.description;
    [self scrollToCurrentDateAnimated:true];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![self currentDate]){
        [self setCurrentDate:[NSDate date]];
    }
    [self layoutViews];
}

- (void)scrollToCurrentDateAnimated:(BOOL)animated {
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.currentDate];
    [_monthTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.month-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
    [_dayTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:components.day-1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
    [_yearTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:animated scrollPosition:UITableViewScrollPositionTop];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _monthTable){
        NSLog(@"[KBDatePicker] month count: %lu", [self calendar].monthSymbols.count);
        //return 1;
        return [self calendar].monthSymbols.count;
    } else if (tableView == _dayTable){
        NSLog(@"[KBDatePicker] currentDate: %@", [self currentDate]);
        NSRange days = [[self calendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.currentDate];
        NSLog(@"[KBDatePicker] day count: %lu", days.length);
        //return 1;
        return days.length;
    } else {
        return 3;
    }
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
        NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.currentDate];
        cell.textLabel.text = [NSString stringWithFormat:@"%lu", year - 1 + indexPath.row];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    NSLog(@"KBDatePicker returning cell: %@ for tv: %@ at indexPath: %@", cell, tableView, indexPath);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.currentDate];
    if (tableView == _monthTable){
        NSInteger month = indexPath.row + 1;
        components.month = month;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != month));
        [self setCurrentDate:newDate];
        [[self dayTable] reloadData];
        [[self yearTable] reloadData];
    } else if (tableView == _dayTable){
        components.day = indexPath.row + 1;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        if (newDate){
            [self setCurrentDate:newDate];
            [[self monthTable] reloadData];
            [[self yearTable] reloadData];
        }
    } else {
        NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.currentDate];
        components.year = year - 1 + indexPath.row;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != components.month));
        [self setCurrentDate:newDate];
        [[self monthTable] reloadData];
        [[self yearTable] reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self scrollToCurrentDateAnimated:true];
}

- (void)layoutViews {
    
    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.monthLabel.text = @"Month";
    self.yearLabel = [[UILabel alloc] init];
    self.yearLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.yearLabel.text = @"Year";
    self.dayLabel = [[UILabel alloc] init];
    self.dayLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.dayLabel.text = @"Day";
    
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = false;
    
    
    self.monthTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.yearTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.dayTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.monthTable.delegate = self;
    self.monthTable.dataSource = self;
    self.yearTable.delegate = self;
    self.yearTable.dataSource = self;
    self.dayTable.delegate = self;
    self.dayTable.dataSource = self;
    
    self.datePickerStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.monthTable, self.dayTable, self.yearTable]];
    self.datePickerStackView.translatesAutoresizingMaskIntoConstraints = false;
    self.datePickerStackView.spacing = 10;
    self.datePickerStackView.axis = UILayoutConstraintAxisHorizontal;
    self.datePickerStackView.alignment = UIStackViewAlignmentFill;
    self.datePickerStackView.distribution = UIStackViewDistributionFillEqually;
    [self.datePickerStackView.widthAnchor constraintEqualToConstant:720].active = true;
    [self.datePickerStackView.heightAnchor constraintEqualToConstant:128].active = true;
    
    [self.view addSubview:self.datePickerStackView];
    [self.view addSubview:self.monthLabel];
    [self.view addSubview:self.yearLabel];
    [self.view addSubview:self.dayLabel];
    [self.view addSubview:self.dateLabel];
    
    [self.datePickerStackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = true;
    [self.datePickerStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = true;
    
    [self.monthLabel.bottomAnchor constraintEqualToAnchor:self.datePickerStackView.topAnchor constant:-60].active = true;
    [self.dayLabel.bottomAnchor constraintEqualToAnchor:self.datePickerStackView.topAnchor constant:-60].active = true;
    [self.dateLabel.bottomAnchor constraintEqualToAnchor:self.dayLabel.topAnchor constant:-81].active = true;
    [self.dateLabel.centerXAnchor constraintEqualToAnchor:self.dayLabel.centerXAnchor].active = true;
    [self.dayLabel.centerXAnchor constraintEqualToAnchor:self.dayTable.centerXAnchor].active = true;
    [self.monthLabel.centerXAnchor constraintEqualToAnchor:self.monthTable.centerXAnchor].active = true;
    [self.yearLabel.centerXAnchor constraintEqualToAnchor:self.yearTable.centerXAnchor].active = true;
    [self.yearLabel.bottomAnchor constraintEqualToAnchor:self.datePickerStackView.topAnchor constant:-60].active = true;
    [self.monthLabel.bottomAnchor constraintEqualToAnchor:self.datePickerStackView.topAnchor constant:-60].active = true;
}



@end
