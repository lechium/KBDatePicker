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
    
    class func todayIn(year: Int) -> Date {
        var dc = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute], from: Date())
        dc.year = year
        return Calendar.current.date(from: dc)! //hopefully this is safe...
    }
    
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
    
    var hourData: [String]?
    var minutesData: [String]?
    var dayData: [String]?
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
        // FIXME: complete
    }
    
    func infiniteNumberOfRowsInSection(section: Int) -> Int {
        return DatePickerView.numberOfCells
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
    
    func loadTimeFromDateAnimated(_: Bool) {
        
    }
    
    func delayedUpdateFocus() {
        DispatchQueue.main.asyncAfter(deadline: (.now() + 1)) {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }
    
    func scrollToValue(_ value: AnyObject, inTableViewType:TableViewTag, animated: Bool) {
        //FIXME
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
    
    func toggleMidnight() {
        
    }
    
    func updateDetailsAtIndexPath(_ indexPath: IndexPath, inTable: DatePickerTableView) {
        
    }
    
    func selectMonthAtIndex(_ index: Int) {
        
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true // FIXME
    }
    
    func toggleMidnightIfNecessaryWithPrevious(_ previous: Int, next: Int) {
        
    }
    
    func contextBrothers(_ context: UITableViewFocusUpdateContext) -> Bool {
        let previousCell = context.previouslyFocusedView
        let newCell = context.nextFocusedView
        return previousCell?.superview == newCell?.superview
    }
    
    func updateDetailsForCountdownTable(_: DatePickerTableView, currentCell: UITableViewCell) {
        
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
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
        let cell = UITableViewCell() // FIXME
        
        return cell
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
        return 720
    }

    func selectionOccured() {
        
    }

}
