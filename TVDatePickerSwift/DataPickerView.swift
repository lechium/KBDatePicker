//
//  DataPickerView.swift
//  TVDatePickerSwift
//
//  Created by kevinbradley on 9/2/21.
//  Copyright © 2021 nito. All rights reserved.
//

import UIKit
import Foundation

extension DefaultStringInterpolation {
    mutating func appendInterpolation(pad value: Int, toWidth width: Int, using paddingCharacter: Character = "0") {
        appendInterpolation(String(format: "%\(paddingCharacter)\(width)d", value))
    }
}

enum DatePickerMode {
    case Time
    case Date
    case DateAndTime
    case CountDownTimer
}

class DatePickerView: UIControl, TableViewProtocol {
    
    static let stackViewHeight: CGFloat = 128.0
    static let numberOfCells: Int = 100000
    override var isEnabled: Bool {
        didSet {
            self.isEnabled = false
        }
    }
    
     init(withHybrdidLayout: Bool) {
        super.init(frame: .zero)
        isEnabled = false //just in case, hopefully this doesnt create a loop or some dumb shit
        hybridLayout = withHybrdidLayout
        _initializeDefaults() //should be able to factor this out, just getting everything working first.
        layoutViews()
    }
    
    func _initializeDefaults() {
        let menuTapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(menuGestureRecognized(_:)))
        menuTapGestureRecognizer.numberOfTapsRequired = 1
        menuTapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        addGestureRecognizer(menuTapGestureRecognizer)
    }
    
    var locale: Locale = Locale.current {
        didSet {
            _updateFormatters()
            adaptModeChange()
        }
    } // default is .current. setting nil returns to default
    var calendar: Calendar = Calendar.current  { // default is .current. setting nil returns to default
        didSet {
            calendar.timeZone = self.timeZone
            adaptModeChange()
        }
    }
    var timeZone: TimeZone = TimeZone.current {
        didSet {
            calendar.timeZone = timeZone
            DatePickerView.sharedDateFormatter.timeZone = timeZone
            DatePickerView.sharedMinimumDateFormatter.timeZone = timeZone
        }
    }
    
    private var currentDate: Date = Date()
    private var pmSelected: Bool = false
    private var countDownHourSelected = 0
    private var countDownMinuteSelected = 0
    private var countDownSecondSelected = 0
    private var selectedRowData: [String: Any] = [:]
    private var minYear = 0
    private var maxYear = 0
    private var tableViews: [DatePickerTableView] = []
    private var currentMonthDayCount = 0
    
    private var yearSelected = 0
    private var monthSelected = 0
    private var daySelected = 0
    private var hourSelected = 0
    private var minuteSelected = 0
    
    var date: Date = Date() {
        didSet {
            currentDate = date
            scrollToCurrentDateAnimated(true)
        }
    }
    
    func setDate(_ date: Date, animated: Bool) {
        currentDate = date
        scrollToCurrentDateAnimated(true)
    }
    
    var countDownDuration: TimeInterval = 0.0 {
        didSet {
            scrollToCurrentDateAnimated(true)
        }
    } // for CountDownTimer, ignored otherwise. default is 0.0. limit is 23:59 (86,399 seconds). value being set is div 60 (drops remaining seconds).
    var minuteInterval: Int?
    
    var showDateLabel: Bool = true {
        didSet {
            self.datePickerLabel.isHidden = !showDateLabel
        }
    }
    var datePickerMode: DatePickerMode = .Date {
        didSet {
            adaptModeChange()
        }
    }
    var topOffset: CGFloat = 20.0
    var hybridLayout: Bool = false // if set to hybrid, we allow manual layout for the width of our view
    
    var minimumDate: Date? {
        didSet {
            if validateMinMax() {
                populateYearsForDateRange()
            }
        }
    }
    var maximumDate: Date? {
        didSet {
            if validateMinMax() {
                populateYearsForDateRange()
            }
        }
    }
    
    func _updateFormatters() {
        DatePickerView.sharedDateFormatter.calendar = calendar
        DatePickerView.sharedMinimumDateFormatter.calendar = calendar
        DatePickerView.sharedDateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: DatePickerView.longDateFormat, options: 0, locale: locale)
        DatePickerView.sharedMinimumDateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: DatePickerView.shortDateFormat, options: 0, locale: locale)
    }
    
    func validateMinMax() -> Bool {
        guard let minimumDate = minimumDate, let maximumDate = maximumDate else {
            return false
        }
        if minimumDate > maximumDate {
            self.minimumDate = nil
            self.maximumDate = nil
            return false
        }
        return true
    }
    
    static var longDateFormat: String = "E, MMM d, yyyy h:mm a"
    static var shortDateFormat: String = "E MMM d"
    
    class var sharedDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = NSTimeZone.local
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: longDateFormat, options: 0, locale: df.locale)
        return df
    }
    
    class var sharedMinimumDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = NSTimeZone.local
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: shortDateFormat, options: 0, locale: df.locale)
        return df
    }
    
    init(hybrid: Bool) {
        hybridLayout = hybrid
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // raw data - this should probably all be private
    
    var hourData: [String] = []
    var minutesData: [String] = []
    var dayData: [String] = []
    var dateData: [String]?
    
    // UI stuff
    
    var datePickerStackView: UIStackView = UIStackView() //just for now
    
    var monthTable: DatePickerTableView?
    var dayTable: DatePickerTableView?
    var yearTable: DatePickerTableView?
    var hourTable: DatePickerTableView?
    var minuteTable: DatePickerTableView?
    var amPMTable: DatePickerTableView?
    var dateTable: DatePickerTableView?
    var countDownHourTable: DatePickerTableView?
    var countDownMinuteTable: DatePickerTableView?
    var countDownSecondsTable: DatePickerTableView?
    
    // Labels
    
    var monthLabel: UILabel?
    var dayLabel: UILabel?
    var yearLabel: UILabel?
    var hourLabel: UILabel?
    var minLabel: UILabel?
    var secLabel: UILabel?
    var datePickerLabel: UILabel = UILabel()
    
    var widthConstraint: NSLayoutConstraint?
    var stackDistribution: UIStackView.Distribution = .fillProportionally
    
    // imp
    
    @objc func menuGestureRecognized(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            if let sv = superview as? DatePickerTableView {
                if let del = sv.delegate as? UIViewController {
                    del.setNeedsFocusUpdate()
                    del.updateFocusIfNeeded()
                }
            } else {
                let app = UIApplication.shared
                let window = app.keyWindow // seriously swift, no way to silence warnings with pragmas? thats effing stupid.
                let root = window?.rootViewController
                if root?.view == self.superview {
                    root?.setNeedsFocusUpdate()
                    root?.updateFocusIfNeeded()
                }
            }
        }
    }
    
    // FIXME: this will only generate from the current month onwards and won't go any further back in the past, will have to do for now
    
    func generateDates(for year: Int) -> [String] {
        var _days = [String]()
        var dc = calendar.dateComponents([.year, .day, .month], from: Date())
        let currentDay = dc.day
        let currentYear = dc.year
        let days = calendar.range(of: .day, in: .year, for: DatePickerView.todayIn(year: year))
        for i in 1...days!.endIndex { //i guess?
            dc.day = i
            if dc.day == currentDay && dc.year == currentYear {
                _days.append("Today")
            } else {
                let newDate = calendar.date(from: dc)
                let currentDay = DatePickerView.sharedMinimumDateFormatter.string(from: newDate!)
                _days.append(currentDay)
            }
        }
        return _days

    }
    
    func currentComponents(units: Set<Calendar.Component>) -> DateComponents {
        return calendar.dateComponents(units, from: date)
    }

    func layoutViews() {
        viewSetupForMode()
        if tableViews.count > 0 {
            return
        }
        
        if datePickerStackView.arrangedSubviews.count > 0 {
            datePickerStackView.removeAllArrangedSubviews()
            datePickerStackView.removeFromSuperview()
        }
        
        datePickerStackView = UIStackView.init(arrangedSubviews: tableViews)
        datePickerStackView.translatesAutoresizingMaskIntoConstraints = false
        datePickerStackView.spacing = 10
        datePickerStackView.axis = .horizontal
        datePickerStackView.alignment = .fill
        datePickerStackView.distribution = stackDistribution
        widthConstraint = datePickerStackView.widthAnchor.constraint(equalToConstant: widthForMode())
        widthConstraint?.isActive = true
        heightAnchor.constraint(equalToConstant: DatePickerView.stackViewHeight+81+60+40).isActive = true
        datePickerStackView.heightAnchor.constraint(equalToConstant: DatePickerView.stackViewHeight).isActive = true
        addSubview(datePickerStackView)
        if !hybridLayout {
            widthAnchor.constraint(equalTo: datePickerStackView.widthAnchor).isActive = true
        }
        datePickerStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        datePickerLabel.translatesAutoresizingMaskIntoConstraints = false
        datePickerLabel.isHidden = !showDateLabel
        addSubview(datePickerLabel)
        datePickerLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        datePickerLabel.topAnchor.constraint(equalTo: datePickerStackView.bottomAnchor, constant: 80).isActive = true
        setupLabelsForMode()
        if let dl = self.dayLabel {
            datePickerStackView.topAnchor .constraint(equalTo: dl.bottomAnchor, constant: 60).isActive = true
        } else {
            datePickerStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
        scrollToCurrentDateAnimated(false)
    }
    
    func layoutForTime() {
        if let ht = hourTable {
            ht.removeFromSuperview()
            hourTable = nil
            minuteTable?.removeFromSuperview()
            minuteTable = nil
            amPMTable?.removeFromSuperview()
            amPMTable = nil
            tableViews.removeAll()
        }
        setupTimeData()
        stackDistribution = .fillProportionally
        hourTable = DatePickerTableView.init(tag: .Hours, delegate: self)
        minuteTable = DatePickerTableView.init(tag: .Minutes, delegate: self)
        amPMTable = DatePickerTableView.init(tag: .AMPM, delegate: self)
        guard let ht = hourTable, let mt = minuteTable, let apt = amPMTable else {
            print("ht mt and apt are nil, this is BAD, should prob throw and exception.")
            return
        }
        ht.customWidth = 70
        mt.customWidth = 80
        apt.customWidth = 70
        apt.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0)
        tableViews = [ht, mt, apt]
    }
    
    func layoutForDate() {
        
        if monthLabel != nil {
            removeDateHeaders()
            monthTable = nil
            yearTable = nil
            dayTable = nil
            tableViews.removeAll()
        }
        populateDaysForCurrentMonth()
        populateYearsForDateRange()
        stackDistribution = .fillProportionally
        
        // labels
        monthLabel = UILabel()
        monthLabel?.translatesAutoresizingMaskIntoConstraints = false
        monthLabel?.text = NSLocalizedString("Month", comment: "")
        yearLabel = UILabel()
        yearLabel?.translatesAutoresizingMaskIntoConstraints = false
        yearLabel?.text = NSLocalizedString("Year", comment: "")
        dayLabel = UILabel()
        dayLabel?.translatesAutoresizingMaskIntoConstraints = false
        dayLabel?.text = NSLocalizedString("Year", comment: "")
        
        // tables
        monthTable = DatePickerTableView.init(tag: .Months, delegate: self)
        yearTable = DatePickerTableView.init(tag: .Years, delegate: self)
        dayTable = DatePickerTableView.init(tag: .Days, delegate: self)
        
        guard let mt = monthTable, let yt = yearTable, let dt = dayTable else {
            print("mt yt and dt are nil, this is BAD, should prob throw and exception.")
            return
        }
        mt.customWidth = 200
        yt.customWidth = 80
        yt.customWidth = 150
        tableViews = [mt, dt, yt]
        addSubview(monthLabel!)
        addSubview(yearLabel!)
        addSubview(dayLabel!)
    }
    
    func layoutLabelsForDate() {
        monthLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        dayLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        yearLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        monthLabel?.centerXAnchor.constraint(equalTo: monthTable!.centerXAnchor).isActive = true
        dayLabel?.centerXAnchor.constraint(equalTo: dayTable!.centerXAnchor).isActive = true
        yearLabel?.centerXAnchor.constraint(equalTo: yearTable!.centerXAnchor).isActive = true
    }
    
    var currentYear: Int {
        return self.calendar.component(.year, from: Date())
    }
    
    func layoutForDateAndTime() {
        if hourTable != nil {
            hourTable?.removeFromSuperview()
            hourTable = nil
            minuteTable?.removeFromSuperview()
            minuteTable = nil
            amPMTable?.removeFromSuperview()
            amPMTable = nil
            dateTable?.removeFromSuperview()
            dateTable = nil
            tableViews.removeAll()
        }
        stackDistribution = .fillProportionally
        dateData = generateDates(for: currentYear)
        setupTimeData()
        
        dateTable = DatePickerTableView.init(tag: .Weekday, delegate: self)
        hourTable = DatePickerTableView.init(tag: .Hours, delegate: self)
        minuteTable = DatePickerTableView.init(tag: .Minutes, delegate: self)
        amPMTable = DatePickerTableView.init(tag: .AMPM, delegate: self)
        
        dateTable?.customWidth = 200
        hourTable?.customWidth = 80
        minuteTable?.customWidth = 80
        amPMTable?.customWidth = 70
        amPMTable?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableViews = [dateTable!, hourTable!, minuteTable!, amPMTable!]
    }
    
    func layoutForCountdownTimer() {
        if countDownHourTable != nil {
            countDownHourTable?.removeFromSuperview()
            countDownHourTable = nil
            countDownMinuteTable?.removeFromSuperview()
            countDownMinuteTable = nil
            countDownSecondsTable?.removeFromSuperview()
            countDownSecondsTable = nil
            tableViews.removeAll()
        }
        
        stackDistribution = .fillProportionally
        
        // tables
        countDownMinuteTable = DatePickerTableView.init(tag: .CDMinutes, delegate: self)
        countDownHourTable = DatePickerTableView.init(tag: .CDHours, delegate: self)
        countDownSecondsTable = DatePickerTableView.init(tag: .CDSeconds, delegate: self)
        countDownMinuteTable?.customWidth = 200
        countDownHourTable?.customWidth = 200
        countDownSecondsTable?.customWidth = 200
        countDownMinuteTable?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        countDownHourTable?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        countDownSecondsTable?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        
        // labels
        hourLabel = UILabel()
        hourLabel?.translatesAutoresizingMaskIntoConstraints = false
        hourLabel?.text = NSLocalizedString("Hours", comment: "")
        minLabel = UILabel()
        minLabel?.translatesAutoresizingMaskIntoConstraints = false
        minLabel?.text = NSLocalizedString("Min", comment: "")
        secLabel = UILabel()
        secLabel?.translatesAutoresizingMaskIntoConstraints = false
        secLabel?.text = NSLocalizedString("Sec", comment: "")
        
        addSubview(hourLabel!)
        addSubview(minLabel!)
        addSubview(secLabel!)
        tableViews = [countDownHourTable!, countDownMinuteTable!, countDownSecondsTable!]
        if countDownDuration == 0 {
            let zero = IndexPath(row: 0, section: 0)
            countDownMinuteTable?.selectedIndexPath = zero
            countDownHourTable?.selectedIndexPath = zero
            countDownSecondsTable?.selectedIndexPath = zero
        }
    }
    
    func removeCountDownLabels() {
        hourLabel?.removeFromSuperview()
        hourLabel = nil
        minLabel?.removeFromSuperview()
        minLabel = nil
        secLabel?.removeFromSuperview()
        secLabel = nil
    }
    
    func removeDateHeaders() {
        dayLabel?.removeFromSuperview()
        dayLabel = nil
        monthLabel?.removeFromSuperview()
        monthLabel = nil
        yearLabel?.removeFromSuperview()
        yearLabel = nil
    }
    
    func layoutLabelsForCountdownTimer() {
        removeDateHeaders()
        
        hourLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        minLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        secLabel?.topAnchor.constraint(equalTo: topAnchor, constant: topOffset).isActive = true
        
        hourLabel?.centerXAnchor.constraint(equalTo: countDownHourTable!.centerXAnchor).isActive = true
        minLabel?.centerXAnchor.constraint(equalTo: countDownMinuteTable!.centerXAnchor).isActive = true
        secLabel?.centerXAnchor.constraint(equalTo: countDownSecondsTable!.centerXAnchor).isActive = true
    }
    
    func layoutLabelsForTime() {
        removeDateHeaders()
        removeCountDownLabels()
    }
    
    func layoutLabelsForDateAndTime() {
        removeDateHeaders()
        removeCountDownLabels()
    }
    
    func setupLabelsForMode() {
        switch datePickerMode {
        case .Time:
            layoutLabelsForTime()
        case .Date:
            layoutLabelsForDate()
        case .DateAndTime:
            layoutLabelsForDateAndTime()
        case .CountDownTimer:
            layoutLabelsForCountdownTimer()
        }
    }
    
    func viewSetupForMode() {
        switch datePickerMode {
        case .Time:
            layoutForTime()
        case .Date:
            layoutForDate()
        case .DateAndTime:
            layoutForDateAndTime()
        case .CountDownTimer:
            layoutForCountdownTimer()
        }
    }
    
    func createNumberArray(count: Int, zeroIndex: Bool, leadingZero:Bool) -> [String] {
        var newArray: [String] = []
        var startIndex = 1
        if zeroIndex { startIndex = 0 }
        for i in startIndex...count+startIndex {
            if leadingZero {
                newArray.append("\(pad: i, toWidth: 2, using:"0")")
            } else {
                newArray.append("\(i)")
            }
        }
        return newArray
    }
    
    func monthData() -> [String] {
        return self.calendar.monthSymbols
    }
    
    func scrollToCurrentDateAnimated(_ animated: Bool) {
        
        switch datePickerMode {
        case .Time:
            loadTimeFromDateAnimated(animated)
        
        case .CountDownTimer:
            countDownHourSelected = Int(countDownDuration / 3600)
            countDownMinuteSelected = Int(countDownDuration / 60) % 60
            countDownSecondSelected = Int(countDownDuration) % 60
            let hourIP = IndexPath(row: countDownHourSelected, section: 0)
            let minIP = IndexPath(row: countDownMinuteSelected, section: 0)
            let secIP = IndexPath(row: countDownSecondSelected, section: 0)
            if let hSip = countDownHourTable?.selectedIndexPath {
                if hSip != hourIP {
                    countDownHourTable?.scrollToRow(at: hourIP, at: .top, animated: animated)
                    countDownHourTable?.selectRow(at: hourIP, animated: true, scrollPosition: .top)
                }
            }
            if let mSip = countDownMinuteTable?.selectedIndexPath {
                if mSip != minIP {
                    countDownMinuteTable?.scrollToRow(at: minIP, at: .top, animated: animated)
                    countDownMinuteTable?.selectRow(at: minIP, animated: true, scrollPosition: .top)
                }
            }
            if let sSip = countDownSecondsTable?.selectedIndexPath {
                if sSip != secIP {
                    countDownSecondsTable?.scrollToRow(at: secIP, at: .top, animated: animated)
                    countDownSecondsTable?.selectRow(at: secIP, animated: true, scrollPosition: .top)
                }
            }
            
        case .Date:
            let components = currentComponents(units: [.year, .month, .day])
            let monthIndex = components.month! - 1 // FIXME: no force unwraps if possible, just trying to get this working
            let monthSymbol = self.monthData()[monthIndex]
            if monthTable?.selectedValue != monthSymbol {
                scrollToValue(monthSymbol, inTableViewType: .Months, animated: animated)
            }
            let dayIndex = components.day!
            let dayString = "\(dayIndex)"
            if dayTable?.selectedValue != dayString {
                scrollToValue(dayString, inTableViewType: .Days, animated: animated)
            }
            let yearIndex = components.year! - 1 // FIXME: ditto
            let yearString = "\(yearIndex)"
            if yearTable?.selectedValue != yearString {
                scrollToValue(yearString, inTableViewType: .Years, animated: animated)
            }
            delayedUpdateFocus()
            
        default:
            loadTimeFromDateAnimated(animated)
            let components = currentComponents(units: [.year, .day])
            let currentDay = components.day!-1
            dateTable?.scrollToRow(at: IndexPath(row: currentDay, section: 0), at: .top, animated: animated)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == monthTable || tableView == dayTable || tableView == hourTable || tableView == minuteTable {
            return infiniteNumberOfRowsInSection(section: section)
        } else if tableView == amPMTable {
            return 2
        } else if tableView == yearTable {
            return maxYear - minYear
        } else if tableView == dateTable {
            return dateData!.count
        } else if tableView == countDownHourTable {
            return 24
        } else if tableView == countDownMinuteTable {
            return 60
        } else if tableView == countDownSecondsTable {
            return 60
        }
        return 0
    }
    
    class func todayIn(year: Int) -> Date {
        var dc = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute], from: Date())
        dc.year = year
        return Calendar.current.date(from: dc)! //hopefully this is safe...
    }
    
    func updateDetailsAtIndexPath(_ indexPath: IndexPath, inTable: DatePickerTableView) {
        // FIXME: so many force unwraps!!
        var components = currentComponents(units: [.month, .day, .year, .hour, .minute])
        var dataSource: [String] = []
        var normalizedIndex = NSNotFound
        
        switch inTable {
        
        case monthTable:
            dataSource = monthData()
            normalizedIndex = indexPath.row % dataSource.count
            components.month = normalizedIndex + 1
            monthSelected = components.month!
            let newDate = calendar.date(from: components)
            currentDate = newDate!
            
        case dayTable:
            dataSource = dayData
            normalizedIndex = indexPath.row & dataSource.count
            components.day = normalizedIndex + 1
            daySelected = components.day!
            let newDate = calendar.date(from: components)
            currentDate = newDate!
            
        case minuteTable:
            dataSource = minutesData
            normalizedIndex = indexPath.row & dataSource.count
            components.minute = normalizedIndex
            minuteSelected = components.minute!
            let newDate = calendar.date(from: components)
            currentDate = newDate!
            
        case hourTable:
            dataSource = hourData
            normalizedIndex = indexPath.row & dataSource.count
            if pmSelected {
                if normalizedIndex != 11 {
                    normalizedIndex += 12
                }
            } else {
                if normalizedIndex == 11 {
                    normalizedIndex += 12
                }
            }
            components.hour = normalizedIndex + 1
            hourSelected = components.hour!
            let newDate = calendar.date(from: components)
            currentDate = newDate!
            
        case yearTable:
            var year = yearTable?.selectedIndexPath?.row
            var adjustment = 1
            if minYear > 1 {
                adjustment = 0
                year = Int((yearTable?.selectedValue)!) // FIXME: ditto
            }
            components.year = year! + adjustment
            var newDate: Date?
            repeat {
                newDate = calendar.date(from: components)
                components.day! -= 1
            } while newDate == nil || calendar.component(.month, from: newDate!) != components.month // FIXME: ditto
            currentDate = newDate!
            
        case amPMTable:
            let previousState = pmSelected
            if indexPath.row == 0 {
                pmSelected = false
                if hourSelected != 0 {
                    if previousState != pmSelected {
                        components.hour! -= 12
                        hourSelected = components.hour!
                        if let date = calendar.date(from: components) {
                            currentDate = date
                        }
                    }
                }
            } else if indexPath.row == 1 {
                pmSelected = true
                if hourSelected != 0 && previousState != pmSelected {
                    components.hour! += 12
                    hourSelected = components.hour!
                    if let date = calendar.date(from: components) {
                        currentDate = date
                    }
                }
            }
            
        case dateTable:
            var dc = currentComponents(units: [.year, .day, .hour, .minute])
            dc.day = indexPath.row+1
            currentDate = calendar.date(from: dc)!
        
        default:
            print("updateDetailsAtIndexPath default")
        }
    
        selectionOccured()
    }

    func selectMonthAtIndex(_ index: Int) {
        var comp = currentComponents(units: [.month, .day, .year])
        var adjustedIndex = index
        if index > monthData().count {
            adjustedIndex = index % monthData().count
        }
        comp.month = adjustedIndex
        date = calendar.date(from: comp)! // TODO: make sure this is always safe
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        guard let tv = tableView as? DatePickerTableView else {
            return true
        }
        if tv.viewTag == .Days {
            let normalized = (indexPath.row & dayData.count) + 1
            if (normalized > currentMonthDayCount) {
                return false
            }
        }
        return true // FIXME: not sure this works properly yet
    }
    
    func toggleMidnight() {
        var index = 1
        if pmSelected {
            index = 0
        }
        amPMTable?.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .top)
        pmSelected = !pmSelected
    }
    
    func toggleMidnightIfNecessaryWithPrevious(_ previous: Int, next: Int) {
        if previous == 11 && next == 12 && !pmSelected {
            toggleMidnight()
        }
        if previous == 12 && next == 1 && !pmSelected{
            toggleMidnight()
        }
    }
    
    func contextBrothers(_ context: UITableViewFocusUpdateContext) -> Bool {
        let previousCell = context.previouslyFocusedView
        let newCell = context.nextFocusedView
        return previousCell?.superview == newCell?.superview
    }
    
    func updateDetailsForCountdownTable(_ tableView: DatePickerTableView, currentCell: UITableViewCell) {
        guard let label = currentCell.textLabel, let text = label.text else {
            return
        }
        //TODO: fix the force upwrapping here
        if tableView == countDownSecondsTable {
            countDownSecondSelected = Int(text)!
        } else if tableView == countDownMinuteTable {
            countDownMinuteSelected = Int(text)!
        } else if tableView == countDownHourTable {
            countDownHourSelected = Int(text)!
        }
        countDownDuration = TimeInterval(countDownSecondSelected + (countDownMinuteSelected*60) + (countDownHourSelected * 3600))
        selectionOccured()
    }
    
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations {
            //animations
            if let table = tableView as? DatePickerTableView {
                if self.contextBrothers(context) {
                    if table.viewTag == .Hours {
                        if let previous = context.previouslyFocusedIndexPath, let nextIndexPath = context.nextFocusedIndexPath {
                            let previousRow = (previous.row % self.hourData.count)+1
                            let nextRow = (nextIndexPath.row % self.hourData.count)+1
                            if (previousRow == 11 && nextRow == 12) || (previousRow == 12 && nextRow == 11){
                                self.toggleMidnight()
                            }
                        }
                    }
                } //contextBrothers
                if let nextIndexPath = context.nextFocusedIndexPath, let nextFocusedView = context.nextFocusedView as? UITableViewCell {
                    table.selectedIndexPath = nextIndexPath
                    if self.datePickerMode == .CountDownTimer {
                        self.updateDetailsForCountdownTable(table, currentCell: nextFocusedView)
                    } else {
                        self.updateDetailsAtIndexPath(nextIndexPath, inTable: table)
                        if table.viewTag == .Months {
                            self.populateDaysForCurrentMonth()
                        }
                    }
                    tableView.selectRow(at: nextIndexPath, animated: false, scrollPosition: .top)
                }
            } //let table = tableView as DatePicker
        } completion: {
            //done
        }

    }
    
    func infiniteNumberOfRowsInSection(section: Int) -> Int {
        return DatePickerView.numberOfCells
    }
    
    func populateYearsForDateRange() { // FIXME: null coalescing operator would be better here probably..
        if let minD = self.minimumDate {
            minYear = calendar.component(.year, from: minD)
        } else {
            minYear = 1
        }
        if let maxD = self.maximumDate {
            maxYear = calendar.component(.year, from: maxD)
        } else {
            maxYear = DatePickerView.numberOfCells
        }
        
        if yearTable?.selectedValue != nil && yearSelected != 0 {
            if minYear > 1 {
                let yearDifference = yearSelected - minYear
                yearTable?.scrollToRow(at: IndexPath.init(row: yearDifference, section: 0), at: .top, animated: false)
            }
        }
        //DispatchQueue.main.async {
            yearTable?.reloadData()
        //}
    }

    func populateDaysForCurrentMonth() {
        if let days = self.calendar.range(of: .day, in: .month, for: date) {
            currentMonthDayCount = days.startIndex + days.endIndex
            if self.dayData != nil {
                dayData = createNumberArray(count: 31, zeroIndex: false, leadingZero: false)
                dayTable?.reloadData()
            }
        }
    }
    
    func setupTimeData() {
        hourData = createNumberArray(count: 12, zeroIndex: false, leadingZero: false)
        minutesData = createNumberArray(count: 60, zeroIndex: true, leadingZero: true)
    }
    
    func startIndexForHours() -> Int {
        return 24996
    }
    
    func startIndexForMinutes() -> Int {
        return 24000
    }
    
    func loadTimeFromDateAnimated(_ animated: Bool) {
        let components = currentComponents(units: [.hour, .minute])
        if var hour = components.hour, let minutes = components.minute {
            let isPM = hour >= 12
            if isPM {
                pmSelected = true
                hour = hour-12
                let amPMIndex = IndexPath(row: 1, section: 0)
                amPMTable?.scrollToRow(at: amPMIndex, at: .top, animated: false)
            }
            let hourValue = "\(hour)"
            let minuteValue = "\(minutes)"
            if let hourTable = hourTable {
                if hourTable.selectedValue != hourValue {
                    self.scrollToValue(hourValue, inTableViewType: .Hours, animated: animated)
                }
            }
            if let minuteTable = minuteTable {
                if minuteTable.selectedValue != minuteValue {
                    self.scrollToValue(minuteValue, inTableViewType: .Minutes, animated: animated)
                }
            }
        }
    }
    
    func delayedUpdateFocus() {
        DispatchQueue.main.asyncAfter(deadline: (.now() + 1)) {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }
    
    func scrollToValue(_ value: String, inTableViewType:TableViewTag, animated: Bool) {
        //FIXME: complete
        var foundIndex = NSNotFound
        var ip: IndexPath = IndexPath(row: 0, section: 0)
        let dayCount = dayData.count
    }
    
    func indexForDays(_ days: Int) -> NSInteger {
        switch days {
        case 28:
            return 24976
        case 29:
            return 24696
        case 30:
            return 24990
        case 31:
            return 24986
        default:
            return 25000
        }
    }
    
    func infiniteCellForTableView(_ tableView: DatePickerTableView, atIndexPath: IndexPath, dataSource:[String]) -> UITableViewCell{
        let cellId = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
        }
        let s = dataSource[atIndexPath.row % dataSource.count]
        cell?.textLabel?.text = s
        return cell!
    }
    
    func amPMCellForRowAtIndexPath(indexPath: IndexPath) -> UITableViewCell {
        let cellId = "amPMCell"
        var cell = amPMTable?.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
        }
        if indexPath.row == 0 {
            cell?.textLabel?.text = self.calendar.amSymbol
        } else {
            cell?.textLabel?.text = self.calendar.pmSymbol
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var reuseId = "year" //change as needed
        if let pickerTableView = tableView as? DatePickerTableView {
            switch pickerTableView {
            
            case hourTable:
                return infiniteCellForTableView(pickerTableView, atIndexPath: indexPath, dataSource: hourData)
            
            case minuteTable:
                return infiniteCellForTableView(pickerTableView, atIndexPath: indexPath, dataSource: minutesData)
            
            case amPMTable:
                return amPMCellForRowAtIndexPath(indexPath: indexPath)
                
            case monthTable:
                return infiniteCellForTableView(pickerTableView, atIndexPath: indexPath, dataSource: monthData())
                
            case dayTable:
                return infiniteCellForTableView(pickerTableView, atIndexPath: indexPath, dataSource: dayData)
                
            case yearTable:
                var cellText = "\(indexPath.row+1)"
                guard let newCell = pickerTableView.dequeueReusableCell(withIdentifier: reuseId) else {
                    cell = UITableViewCell.init(style: .default, reuseIdentifier: reuseId)
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.text = cellText
                    return cell
                }
                cell = newCell // janky...
                cell.textLabel?.textAlignment = .center
                if (minYear > 1) {
                    cellText = "\(indexPath.row + minYear + 1)"
                }
                cell.textLabel?.text = cellText
            
            case dateTable:
                reuseId = "date"
                let cellText = dateData![indexPath.row] // FIXME: force unwrap bad
                guard let newCell = pickerTableView.dequeueReusableCell(withIdentifier: reuseId) else {
                    cell = UITableViewCell.init(style: .default, reuseIdentifier: reuseId)
                    cell.textLabel?.text = cellText
                    return cell
                }
                cell = newCell // janky...
                cell.textLabel?.text = cellText
                
            case countDownSecondsTable, countDownSecondsTable, countDownMinuteTable:
                reuseId = "cd"
                let cellText = "\(indexPath.row)"
                guard let newCell = pickerTableView.dequeueReusableCell(withIdentifier: reuseId) else {
                    cell = UITableViewCell.init(style: .default, reuseIdentifier: reuseId)
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.text = cellText
                    return cell
                }
                cell = newCell // janky...
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.text = cellText
            default:
                print("default in cellForRowAtIndexPath")
            }
        }
        return cell
    }
    
    func selectionOccured() {
        sendActions(for: .valueChanged)
        if self.showDateLabel {
            datePickerLabel.isHidden = false
            var details: String?
            if datePickerMode == .CountDownTimer {
                details = "countdown duration: \(countDownDuration) seconds"
            } else {
                details = DatePickerView.sharedDateFormatter.string(from: date)
            }
            datePickerLabel.text = details
        } else {
            datePickerLabel.isHidden = true
        }
    }

    func adaptModeChange() {
        self.removeAllSubviews()
        self.layoutViews()
        if datePickerMode != .CountDownTimer {
            countDownDuration = 0
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: widthForMode(), height: DatePickerView.stackViewHeight+81+60+40)
    }
    
    func widthForMode() -> CGFloat {
        switch datePickerMode {
        case .Date:
            return 500
        case .Time:
            return 350
        case .DateAndTime:
            return 650
        case .CountDownTimer:
            return 550
        }
        //return 720
    }

}
