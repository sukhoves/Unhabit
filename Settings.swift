//
//  Settings.swift
//  UnhabitDemo
//
//  Created by Evgenii Sukhov on 29.01.2026.
//

import Foundation
import SwiftUI
import Combine
import ActivityKit

// MARK: - Difficulty Level
enum DifficultyLevel: Int, Codable, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3
    
    var title: String {
        switch self {
        case .easy: return "Легкий"
        case .medium: return "Средний"
        case .hard: return "Сложный"
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Плавное снижение"
        case .medium: return "Баланс скорости и комфорта"
        case .hard: return "Интенсивное снижение"
        }
    }
    
    var daysInterval: Int {
        switch self {
        case .easy: return 3
        case .medium: return 2
        case .hard: return 1
        }
    }
    
    var multiplier: Double {
        switch self {
        case .easy: return 0.5
        case .medium: return 1.0
        case .hard: return 1.5
        }
    }
}

// MARK: - App Settings Manager
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let sharedDefaults: UserDefaults
    
    @Published var baseTimerInterval: TimeInterval = 30
    @Published var baseTimerAdd: TimeInterval = 15
    @Published var difficultyLevel: DifficultyLevel = .easy
    @Published var firstRecordDate: Date?
    @Published var lastRecordDate: Date?
    @Published var lastIncreaseDate: Date?
    @Published var qtyCigarette: Int = 1
    @Published var addIntervalMap: [Date] = []
    @Published var initialCigaretteCount: Int = 10
    @Published var currentIncreaseIndex: Int = 0
    @Published var smokingHours: Int = 12
    @Published var hasReached24HourGoal: Bool = false
    private init() {
        sharedDefaults = UserDefaults(suiteName: "group.com.TEAM_ID_PLACEHOLDER.Unhabit")!
        loadSettings()
        setupDateObserver()
    }
    
    private var localCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    // MARK: - Computed Properties
    var daysInterval: Int {
        return difficultyLevel.daysInterval
    }
    
    var multiplier: Double {
        return difficultyLevel.multiplier
    }
    
    var targetCigarettes: Int {
        return max(1, initialCigaretteCount - currentIncreaseIndex)
    }
    
    var is24HourGoalReached: Bool {
        return baseTimerInterval >= 24 * 3600
    }
    
    // MARK: - Save/Load
    private func loadSettings() {
        baseTimerInterval = sharedDefaults.double(forKey: "baseTimerInterval")
        if baseTimerInterval == 0 { baseTimerInterval = 30 }
        
        baseTimerAdd = sharedDefaults.double(forKey: "baseTimerAdd")
        if baseTimerAdd == 0 { baseTimerAdd = 15 }
        
        if let rawValue = sharedDefaults.object(forKey: "difficultyLevel") as? Int {
            difficultyLevel = DifficultyLevel(rawValue: rawValue) ?? .easy
        }
        
        if let firstDate = sharedDefaults.object(forKey: "firstRecordDate") as? Date {
            firstRecordDate = firstDate
        }
        
        if let lastDate = sharedDefaults.object(forKey: "lastRecordDate") as? Date {
            lastRecordDate = lastDate
        }
        
        if let lastIncDate = sharedDefaults.object(forKey: "lastIncreaseDate") as? Date {
            lastIncreaseDate = lastIncDate
        }
        
        qtyCigarette = sharedDefaults.integer(forKey: "qtyCigarette")
        if qtyCigarette == 0 { qtyCigarette = 1 }
        
        initialCigaretteCount = sharedDefaults.integer(forKey: "initialCigaretteCount")
        if initialCigaretteCount == 0 { initialCigaretteCount = 10 }
        
        currentIncreaseIndex = sharedDefaults.integer(forKey: "currentIncreaseIndex")
        
        smokingHours = sharedDefaults.integer(forKey: "smokingHours")
        if smokingHours == 0 { smokingHours = 12 }
        
        hasReached24HourGoal = sharedDefaults.bool(forKey: "hasReached24HourGoal")
        
        if let datesData = sharedDefaults.array(forKey: "addIntervalMap") as? [Date] {
            addIntervalMap = datesData
        }
    }
    
    private func saveAll() {
        sharedDefaults.set(baseTimerInterval, forKey: "baseTimerInterval")
        sharedDefaults.set(baseTimerAdd, forKey: "baseTimerAdd")
        sharedDefaults.set(difficultyLevel.rawValue, forKey: "difficultyLevel")
        sharedDefaults.set(firstRecordDate, forKey: "firstRecordDate")
        sharedDefaults.set(lastRecordDate, forKey: "lastRecordDate")
        sharedDefaults.set(lastIncreaseDate, forKey: "lastIncreaseDate")
        sharedDefaults.set(qtyCigarette, forKey: "qtyCigarette")
        sharedDefaults.set(initialCigaretteCount, forKey: "initialCigaretteCount")
        sharedDefaults.set(currentIncreaseIndex, forKey: "currentIncreaseIndex")
        sharedDefaults.set(smokingHours, forKey: "smokingHours")
        sharedDefaults.set(hasReached24HourGoal, forKey: "hasReached24HourGoal")
        sharedDefaults.set(addIntervalMap, forKey: "addIntervalMap")
        sharedDefaults.synchronize()
        
        print("Settings saved: timer=\(baseTimerInterval), qty=\(qtyCigarette), initial=\(initialCigaretteCount), index=\(currentIncreaseIndex), 24hGoal=\(hasReached24HourGoal)")
    }
    
    // MARK: - Public Methods
    func setDifficulty(_ level: DifficultyLevel) {
        difficultyLevel = level
        regenerateIntervalMap()
        saveAll()
    }
    
    func setTimerInterval(_ interval: TimeInterval) {
        baseTimerInterval = interval
        saveAll()
    }
    
    func setTimerAdd(_ add: TimeInterval) {
        baseTimerAdd = add
        regenerateIntervalMap()
        saveAll()
    }
    
    func setQtyCigarette(_ qty: Int) {
        qtyCigarette = qty
        saveAll()
    }
    
    func recordFirstSmoke(date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        firstRecordDate = startOfDay
        lastRecordDate = startOfDay
        saveAll()
        regenerateIntervalMap()
        
        print("First record set to: \(startOfDay)")
    }
    
    func recordSmoke(date: Date, qty: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        lastRecordDate = startOfDay
        qtyCigarette = qty
        saveAll()
        
        print("Recorded: \(qty) cigarettes on \(startOfDay)")
    }
    
    // MARK: - Initial Setup Methods
    func calculateAndSetInitialInterval(startHour: Int, endHour: Int, cigaretteCount: Int) {
        guard startHour >= 0 && startHour <= 23,
              endHour >= 0 && endHour <= 23,
              cigaretteCount > 0 else {
            print("Invalid input data")
            return
        }
        
        // Коэффициент уменьшения для тестирования (1/100)
        let testMultiplier: TimeInterval = 0.01
        
        let calculatedHours: Int
        if endHour >= startHour {
            calculatedHours = endHour - startHour
        } else {
            calculatedHours = (24 - startHour) + endHour
        }
        
        let totalHours = calculatedHours == 0 ? 24 : calculatedHours
        
        let totalSeconds = TimeInterval(totalHours * 3600)
        let calculatedInterval = totalSeconds / TimeInterval(cigaretteCount)

        let roundedInterval = (calculatedInterval / 30).rounded() * 30
        
        let finalInterval = max(roundedInterval, 300) * testMultiplier // ← Добавил множитель
        
        baseTimerInterval = finalInterval
        initialCigaretteCount = cigaretteCount
        smokingHours = totalHours
        currentIncreaseIndex = 0
        hasReached24HourGoal = false
        
        recordFirstSmoke(date: Date())
        
        regenerateIntervalMap()
        
        print("Calculated initial interval:")
        print("  Start hour: \(startHour)")
        print("  End hour: \(endHour)")
        print("  Smoking hours: \(totalHours)")
        print("  Initial cigarette count: \(cigaretteCount)")
        print("  Original interval: \(max(roundedInterval, 300)) seconds (\(max(roundedInterval, 300)/60) minutes)")
        print("  TEST interval (x\(testMultiplier)): \(finalInterval) seconds (\(finalInterval/60) minutes)")
        
        saveAll()
    }
    
    // MARK: - Interval Map Logic
    private func regenerateIntervalMap() {
        guard let firstDate = firstRecordDate else {
            addIntervalMap = []
            return
        }
        
        var map: [Date] = []
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let firstDateStartOfDay = calendar.startOfDay(for: firstDate)
        
        var currentDate = calendar.date(byAdding: .day, value: daysInterval, to: firstDateStartOfDay)!
        
        for i in 0..<(initialCigaretteCount) {
            let targetCigarettes = initialCigaretteCount - i
            if targetCigarettes >= 1 {

                let dateStartOfDay = calendar.startOfDay(for: currentDate)
                map.append(dateStartOfDay)
                
                currentDate = calendar.date(byAdding: .day, value: daysInterval, to: currentDate)!
            }
        }
        
        addIntervalMap = map
        saveAll()
        
        print("Interval map regenerated with \(map.count) dates")
        print("Calendar timezone: \(calendar.timeZone)")
        print("First date: \(firstDateStartOfDay)")
        print("Days interval: \(daysInterval)")
        print("Will reduce from \(initialCigaretteCount) to 1 cigarette over \(initialCigaretteCount - 1) increases")
        print("Then will set 24-hour interval on increase #\(initialCigaretteCount)")
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        
        for (index, date) in map.prefix(min(5, map.count)).enumerated() {
            if index < initialCigaretteCount - 1 {
                let target = initialCigaretteCount - (index + 1)
                print("  \(index+1). \(formatter.string(from: date)) -> target: \(target) cigarettes")
            } else if index == initialCigaretteCount - 1 {
                print("  \(index+1). \(formatter.string(from: date)) -> FINAL: 24-hour interval")
            }
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    func shouldIncreaseIntervalToday() -> Bool {
        guard !addIntervalMap.isEmpty else { return false }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)
        
        if let lastIncrease = lastIncreaseDate {
            let lastIncreaseStartOfDay = calendar.startOfDay(for: lastIncrease)
            if calendar.isDate(lastIncreaseStartOfDay, inSameDayAs: todayStartOfDay) {
                return false
            }
        }
        
        for date in addIntervalMap {
            if calendar.isDate(date, inSameDayAs: todayStartOfDay) {
                return true
            }
        }
        
        return false
    }
    
    func increaseTimerInterval() {
        currentIncreaseIndex += 1
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Коэффициент уменьшения для тестирования (1/100)
        let testMultiplier: TimeInterval = 0.01
        
        if currentIncreaseIndex < initialCigaretteCount {

            let targetCigarettes = initialCigaretteCount - currentIncreaseIndex
            
            let totalSeconds = TimeInterval(smokingHours * 3600)
            let newInterval = totalSeconds / TimeInterval(targetCigarettes)
            

            let roundedInterval = (newInterval / 30).rounded() * 30
            
            // Применяем множитель
            let calculatedInterval = max(roundedInterval, 300)
            baseTimerInterval = calculatedInterval * testMultiplier
            
            print("Increase #\(currentIncreaseIndex):")
            print("  Target cigarettes: \(targetCigarettes)")
            print("  Calculated interval: \(calculatedInterval) seconds (\(calculatedInterval/60) minutes)")
            print("  TEST interval (x\(testMultiplier)): \(baseTimerInterval) seconds (\(baseTimerInterval/60) minutes)")
            
        } else if currentIncreaseIndex == initialCigaretteCount {

            let full24Hours = 24 * 3600 // 24 часа в секундах
            baseTimerInterval = Double(full24Hours) * testMultiplier // Множитель
            hasReached24HourGoal = true
            
            print("FINAL INCREASE #\(currentIncreaseIndex):")
            print("  REACHED 24-HOUR GOAL!")
            print("  Full interval: 24 hours (86400 seconds)")
            print("  TEST interval (x\(testMultiplier)): \(baseTimerInterval) seconds (\(baseTimerInterval/60) minutes)")
            
        } else {
            print("Already reached 24-hour goal")
            return
        }
        
        lastIncreaseDate = Date()
        
        cleanupIntervalMap()
        
        saveAll()
    }
    
    // Очистка карты от прошедших дат
    func cleanupIntervalMap() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)
        
        addIntervalMap = addIntervalMap.filter { date in
            let dateStartOfDay = calendar.startOfDay(for: date)
            return dateStartOfDay > todayStartOfDay
        }
        
        addIntervalMap.sort()
        saveAll()
    }
    
    // MARK: - Очистка устаревших Live Activities
    func cleanupStaleActivities() {
        Task {
            let activities = Activity<TimeTrackingAttributes>.activities
            
            for activity in activities {
                let state = activity.content.state
                let now = Date()
                
                if state.endTime.addingTimeInterval(600) < now {
                    await activity.end(
                        ActivityContent(state: state, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    print("🗑️ Очищена устаревшая активность: \(activity.id)")
                }
            }
        }
    }
    
    // MARK: - Проверка и остановка завершенных активностей
    func checkAndEndCompletedActivities() {
        Task {
            let activities = Activity<TimeTrackingAttributes>.activities
            
            for activity in activities {
                let state = activity.content.state
                let now = Date()
                
                if state.endTime <= now {
                    await activity.end(
                        ActivityContent(state: state, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    print("⏹️ Остановлена завершенная активность: \(activity.id)")
                }
            }
        }
    }
    
    // MARK: - Date Observer
    private func setupDateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkDateChange),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkDateChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }
    
    @objc private func checkDateChange() {
        print("🔄 Checking date change...")
        
        if shouldIncreaseIntervalToday() {
            DispatchQueue.main.async { [weak self] in
                self?.increaseTimerInterval()
                print("📈 Timer interval increased due to schedule!")
            }
        }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        if hour == 0 && minute == 0 {
            if shouldIncreaseIntervalToday() {
                DispatchQueue.main.async { [weak self] in
                    self?.increaseTimerInterval()
                    print("⏰ Timer interval increased at midnight!")
                }
            }
        }
        
        checkAndEndCompletedActivities()
    }
    
    // MARK: - Timer Calculation
    func calculateTimerDuration() -> TimeInterval {
        if qtyCigarette == 1 {
            return baseTimerInterval
        } else {
            return baseTimerInterval + ((Double(qtyCigarette)-1) * baseTimerInterval) * multiplier
        }
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours >= 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return String(format: "%dд %02d:%02d", days, remainingHours, minutes)
        } else if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
