//
//  FSCalendarScopeViewController.swift
//  FSCalendarSwiftExample
//
//  Created by dingwenchao on 30/12/2016.
//  Copyright © 2016 wenchao. All rights reserved.
//

import UIKit

class FSCalendarScopeExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var animationSwitch: UISwitch!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        
        self.calendar.select(Date())
        
        self.view.addGestureRecognizer(self.scopeGesture)
        self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calendar.scope = .week
        self.calendar.numbersWeekOfMonth = 2
        self.calendar.appearance.separators = .interRows
        self.calendar.appearance.borderRadius = 0
        self.calendar.appearance.eventOffset = CGPoint(x: 0, y: -40)
        self.calendar.rowHeight = 56
        self.calendar.ratioContentInCell = 1
        self.calendar.setSectionInsetCollectionView(.zero)
        self.calendar.preferPaddingRow = 0
        
        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
        self.calendar.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(didBecome), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        print("\(#function)")
    }
    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
            
        }
        return shouldBegin
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("did select date \(self.dateFormatter.string(from: date))")
        let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        print("selected dates is \(selectedDates)")
        if calendar.scope == .month {
            if monthPosition == .next || monthPosition == .previous {
                calendar.setCurrentPage(date, animated: true)
            }
        }
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("\(self.dateFormatter.string(from: calendar.currentPage))")
    }

    func calendarCurrentPageFinished(_ calendar: FSCalendar) {
        print("calendarCurrentPageFinished \(self.dateFormatter.string(from: calendar.currentPage))")
    }

    func calendar(_ calendar: FSCalendar, beganLongPressforCell cell: FSCalendarCell, date: Date, at indexPath: IndexPath) {

        print("beganLongPressforell \(self.dateFormatter.string(from: date))")
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        if date.compare(Date()) == .orderedAscending {
            return 0
        }
        return 1
    }

    // MARK:- UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [2,80][section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let identifier = ["cell_month", "cell_week"][indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
           
            return cell
        }
    }
    
    
    // MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let scope: FSCalendarScope = (indexPath.row == 0) ? .month : .week
            self.calendar.setScope(scope, animated: self.animationSwitch.isOn)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    // MARK:- Target actions
    
    @IBAction func toggleClicked(sender: AnyObject) {
        if self.calendar.scope == .month {
            self.calendar.setScope(.week, animated: self.animationSwitch.isOn)
        } else {
            self.calendar.setScope(.month, animated: self.animationSwitch.isOn)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var component = DateComponents()
        component.day = Int(scrollView.contentOffset.y) / 44
        let newDate = Calendar.current.date(byAdding: component, to: Date())!
        
        let timeCurrentDate = calendar.currentPage.timeIntervalSince1970
        let timeNewDate = newDate.timeIntervalSince1970
//                    if timeCurrentDate > timeNewDate {
//                        component.day = -14
//                        let oldDate = Calendar.current.date(byAdding: component, to: Date())!
//                        calendar.setCurrentPage(oldDate, animated: false)
//                    } else if timeNewDate - timeCurrentDate >= 1209600 {
//                        calendar.setCurrentPage(newDate, animated: false)
//                    }
            calendar.select(newDate, scrollToDate: true)
    }
    @objc func didBecome() {
        print("Time : \(String(describing: self.calendar.today))")

        self.calendar.today = Date()
        print("New time : \(String(describing: self.calendar.today))")

    }
}
