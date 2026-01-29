//
//  ContentView.swift
//  Unhabit
//
//  Created by Evgenii Sukhov on 16.01.2026.
//

import SwiftUI
import ActivityKit
import Combine
import UserNotifications

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isTrackingTime = false
    @State private var startTime: Date? = nil
    @State private var activity: Activity<TimeTrackingAttributes>? = nil
    @State private var debugText = "Статус: неактивно"
    @State private var showingSettings = false
    @State private var showingDifficultySelector = false
    @State private var showingInitialSetup = false
    @State private var remainingTime: TimeInterval = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var startHour = 8
    @State private var endHour = 22
    @State private var initialCigaretteCount = 10 // Только для расчета, не для qtyCigarette
    
    // Проверяем, был ли уже сделан начальный setup
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    
    var body: some View {
        VStack {
            // Заголовок с шестеренкой
            HStack {
                
                Text("Таймер")
                        .font(.title)
                        .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingSettings = true
                    print("⚙️ Нажата кнопка настроек")
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.largeTitle)
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            Spacer()
            
            // Информационный блок с таймером
            VStack {
                Text("До следующего перекура")
                    .font(.headline)
                
                if let currentStartTime = startTime {
                    Text(formatTimeInterval(remainingTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding()
                        .frame(width: 260)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                        .onReceive(timer) { _ in
                            guard isTrackingTime else { return }
                            updateRemainingTime(startTime: currentStartTime)
                        }
                } else {
                    Text("\(formatTimeInterval(settings.baseTimerInterval + ((Double(settings.qtyCigarette)-1) * settings.baseTimerInterval) * settings.multiplier))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding()
                        .frame(width: 260)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                }
                
                Text("Количество: ×\(settings.qtyCigarette)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
            ZStack {
                // Фоновый HStack с элементами по краям
                HStack {
                    // Текст количества слева
                    Text("×\(settings.qtyCigarette)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 50, alignment: .leading)
                        .foregroundColor(isTrackingTime ? .gray : .primary)
                    
                    Spacer()
                    
                    // Кастомные кнопки + и -
                    HStack(spacing: 12) {
                        // Кнопка минус
                        Button(action: {
                            if settings.qtyCigarette > 1 && !isTrackingTime {
                                let newValue = settings.qtyCigarette - 1
                                settings.setQtyCigarette(newValue)
                                print("📉 Изменено количество сигарет: \(newValue)")
                                
                                if isTrackingTime, let start = startTime {
                                    updateRemainingTime(startTime: start)
                                    updateLiveActivity(startTime: start)
                                }
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundColor(isTrackingTime ? .gray : .primary)
                        }
                        .disabled(settings.qtyCigarette <= 1 || isTrackingTime)
                        
                        Divider()
                            .frame(height: 20)
                            .foregroundColor(isTrackingTime ? .gray : .primary)
                        
                        // Кнопка плюс
                        Button(action: {
                            if settings.qtyCigarette < 100 && !isTrackingTime {
                                let newValue = settings.qtyCigarette + 1
                                settings.setQtyCigarette(newValue)
                                print("📈 Изменено количество сигарет: \(newValue)")
                                
                                if isTrackingTime, let start = startTime {
                                    updateRemainingTime(startTime: start)
                                    updateLiveActivity(startTime: start)
                                }
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(isTrackingTime ? .gray : .blue)
                        }
                        .disabled(settings.qtyCigarette >= 100 || isTrackingTime)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .opacity(isTrackingTime ? 0.5 : 1)
                }
                .padding(.horizontal, 20)
                
                // Кнопка play абсолютно по центру
                Button(action: {
                    if !isTrackingTime {
                        toggleTracking()
                        print("▶️ Нажата кнопка таймера")
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 58))
                        .foregroundColor(isTrackingTime ? .gray : .blue)
                        .opacity(isTrackingTime ? 0.5 : 1)
                }
                .padding(.vertical, 12)
                .disabled(isTrackingTime)
            }
            .cornerRadius(24)
            .padding(.horizontal, 20)
            
            Spacer()
            
           // Button("Сбросить все") {
            //    resetAll()
          //  }
            
            // Прогресс (скрытая часть для отладки)
            VStack {
               
        
                // Отображаем только этап прогресса
                if settings.firstRecordDate != nil && !settings.hasReached24HourGoal {
                    VStack(spacing: 5) {
                        Text("Этап 1: Уменьшение до 1 сигареты")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        ProgressView(value: Double(settings.currentIncreaseIndex),
                                   total: Double(settings.initialCigaretteCount - 1))
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(.blue)
                        
                        if settings.currentIncreaseIndex < settings.initialCigaretteCount - 1 {
                            let nextTarget = settings.initialCigaretteCount - (settings.currentIncreaseIndex + 1)
                            
                            // Показываем дату следующего увеличения
                            if let nextDate = settings.addIntervalMap.first {
                                HStack {
                                    Text("Следующая цель: \(nextTarget) сигарет")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(nextDate))
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Text("Следующая цель: \(nextTarget) сигарет")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        } else if settings.currentIncreaseIndex == settings.initialCigaretteCount - 1 {
                            // Последний шаг перед 24 часами
                            if let finalDate = settings.addIntervalMap.first {
                                HStack {
                                    Text("Следующий шаг: 24-часовой интервал!")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(finalDate))
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            } else {
                                Text("Следующий шаг: 24-часовой интервал!")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 3)
                }
               
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingInitialSetup) {
            InitialSetupSheetView(
                startHour: $startHour,
                endHour: $endHour,
                cigaretteCount: $initialCigaretteCount,
                onComplete: {
                    completeInitialSetup()
                }
            )
        }
        .alert("Выберите подход", isPresented: $showingDifficultySelector) {
            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                Button(level.title) {
                    settings.setDifficulty(level)
                }
            }
            Button("Позже", role: .cancel) { }
        } message: {
            Text("Выберите уровень сложности для программы снижения курения")
        }
        .onAppear {
            print("=== CONTENTVIEW APPEARED ===")
            print("🕐 Текущее время: \(Date())")
            print("🚬 Текущее количество сигарет: \(settings.qtyCigarette)")
            print("⏲️ Таймер активен: \(isTrackingTime)")
            
            // Проверяем и запрашиваем разрешения на уведомления
            checkAndRequestNotificationPermissions()
            
            checkLiveActivityCapability()
            restoreActivityState()
            
            // Показываем окно начальной настройки при первом запуске
            if !hasCompletedInitialSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingInitialSetup = true
                }
            }
            
            // Очищаем карту от прошедших дат
            print("🔄 До cleanupIntervalMap:")
            print("📅 addIntervalMap: \(settings.addIntervalMap)")
            settings.cleanupIntervalMap()
            print("✅ После cleanupIntervalMap:")
            print("📅 addIntervalMap: \(settings.addIntervalMap)")
            
            // Очищаем устаревшие активности
            settings.cleanupStaleActivities()
            
            // Проверяем увеличение интервала при запуске
            print("🔍 Проверяем shouldIncreaseIntervalToday()...")
            if settings.shouldIncreaseIntervalToday() {
                print(">>> ВЫЗЫВАЕМ increaseTimerInterval() <<<")
                settings.increaseTimerInterval()
                debugText = "Интервал увеличен! Новый: \(settings.formatTimeInterval(settings.baseTimerInterval))"
                print("📈 Интервал увеличен! Новый: \(settings.formatTimeInterval(settings.baseTimerInterval))")
            } else {
                print(">>> НЕ увеличиваем интервал <<<")
                print("📅 lastIncreaseDate: \(settings.lastIncreaseDate?.description ?? "nil")")
                print("⏱️ baseTimerInterval: \(settings.baseTimerInterval)")
            }
            
            if let startTime = startTime {
                updateRemainingTime(startTime: startTime)
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
            print("👋 ContentView скрылся")
        }
    }
    
    // MARK: - Helper Methods
    private func completeInitialSetup() {
        // Рассчитываем и устанавливаем базовый интервал
        // initialCigaretteCount используется ТОЛЬКО для расчета интервала
        settings.calculateAndSetInitialInterval(
            startHour: startHour,
            endHour: endHour,
            cigaretteCount: initialCigaretteCount
        )
        
        // НЕ устанавливаем qtyCigarette - оно остается 1 (или текущее значение)
        // qtyCigarette управляется только степпером на главном экране
        
        // Помечаем setup как завершенный
        hasCompletedInitialSetup = true
        
        // После расчета показываем окно выбора сложности
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingDifficultySelector = true
        }
        
        let progressText = """
        ✅ Начальная настройка завершена!
        ⏰ Часы курения: \(settings.smokingHours) часов
        🚬 Начальное количество: \(initialCigaretteCount) сигарет
        ⏱️ Базовый интервал: \(settings.formatTimeInterval(settings.baseTimerInterval))
        📊 Всего увеличений запланировано: \(settings.initialCigaretteCount)
        """
        
        debugText = progressText
        print(progressText)
    }
    
    private func calculateSmokingHours() -> Int {
        if endHour >= startHour {
            return endHour - startHour
        } else {
            return (24 - startHour) + endHour
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func updateRemainingTime(startTime: Date) {
        guard isTrackingTime else { return }
        
        let duration = settings.calculateTimerDuration()
        let elapsed = Date().timeIntervalSince(startTime)
        remainingTime = max(0, duration - elapsed)
        
        if remainingTime <= 0 && isTrackingTime {
            // Таймер завершился
            debugText = "✅ Таймер завершен! Можно сделать перекур."
            print("✅ Таймер завершен! Можно сделать перекур.")
            
            // Автоматически останавливаем все
            stopTimerAndReset()
        }
    }

    private func stopTimerAndReset() {
        // Останавливаем таймер
        isTrackingTime = false
        timer.upstream.connect().cancel()
        
        // Останавливаем Live Activity
        stopLiveActivity()
        
        // Сбрасываем состояние
        startTime = nil
        activity = nil
        
        // Отправляем уведомление ПОСЛЕ остановки всех активностей
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sendTimerCompletionNotification()
        }
        
        print("⏹️ Таймер автоматически остановлен после завершения")
    }

    private func sendTimerCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Таймер завершён"
        content.body = "Можно сделать перекур"
        content.sound = .default
        content.interruptionLevel = .timeSensitive // Важно: делаем уведомление более приоритетным
        content.categoryIdentifier = "TIMER_COMPLETED_CATEGORY"
        
        // Используем несколько типов триггеров для надежности
        let request1 = UNNotificationRequest(
            identifier: "timer_completed_immediate_\(UUID().uuidString)",
            content: content,
            trigger: nil // Немедленное уведомление
        )
        
        let request2 = UNNotificationRequest(
            identifier: "timer_completed_delayed_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        
        let center = UNUserNotificationCenter.current()
        
        // Добавляем оба уведомления для надежности
        center.add(request1) { error in
            if let error = error {
                print("❌ Ошибка отправки немедленного уведомления: \(error)")
                // Пробуем второе с небольшой задержкой
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    center.add(request2) { error in
                        if let error = error {
                            print("❌ Ошибка отправки отложенного уведомления: \(error)")
                        } else {
                            print("✅ Отложенное уведомление отправлено")
                        }
                    }
                }
            } else {
                print("✅ Немедленное уведомление отправлено")
            }
        }
    }
    
    private func calculateEndTime(startTime: Date) -> Date {
        let duration = settings.calculateTimerDuration()
        return startTime.addingTimeInterval(duration)
    }
    
    // MARK: - Timer Methods
    private func toggleTracking() {
        // Только запуск, остановка недоступна
        if isTrackingTime {
            return
        }
        
        isTrackingTime = true
        startTime = .now
        updateRemainingTime(startTime: .now)
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        debugText = "Запуск таймера..."
        print("▶️ Запуск таймера...")
        startLiveActivity()
        
        // Если это первый запуск, устанавливаем дату
        if settings.firstRecordDate == nil {
            settings.recordFirstSmoke(date: .now)
            print("📝 Первая запись установлена: \(Date())")
        }
    }
    
    private func startLiveActivity() {
        guard let startTime = startTime else { return }
        
        let attributes = TimeTrackingAttributes()
        let endTime = calculateEndTime(startTime: startTime)
        let state = TimeTrackingAttributes.ContentState(
            startTime: startTime,
            endTime: endTime,
            qtyCigarette: settings.qtyCigarette
        )
        
        do {
            activity = try Activity<TimeTrackingAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: endTime),
                pushType: nil
            )
            
            debugText = "✅ Live Activity запущена\nID: \(activity?.id ?? "нет")\nКоличество: \(settings.qtyCigarette)"
            print("✅ Live Activity запущена. ID: \(activity?.id ?? "нет"), Количество: \(settings.qtyCigarette)")
            
        } catch {
            debugText = "❌ Ошибка запуска: \(error.localizedDescription)"
            print("❌ Ошибка запуска Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity(startTime: Date) {
        guard let activity = activity, isTrackingTime else { return }
        
        let endTime = calculateEndTime(startTime: startTime)
        let updatedState = TimeTrackingAttributes.ContentState(
            startTime: startTime,
            endTime: endTime,
            qtyCigarette: settings.qtyCigarette
        )
        
        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: endTime))
        }
    }
    
    private func stopLiveActivity() {
        guard let activity = activity else {
            print("ℹ️ Нет активной Live Activity для остановки")
            return
        }
        
        // Получаем текущее состояние
        let currentState = activity.content.state
        let now = Date()
        
        Task {
            // Всегда останавливаем немедленно с текущим временем
            let finalState = TimeTrackingAttributes.ContentState(
                startTime: currentState.startTime,
                endTime: now, // Устанавливаем время окончания как текущее
                qtyCigarette: currentState.qtyCigarette
            )
            
            await activity.end(
                ActivityContent(state: finalState, staleDate: now),
                dismissalPolicy: .immediate
            )
            
            await MainActor.run {
                self.debugText = "✅ Live Activity остановлена"
                self.activity = nil
                print("⏹️ Live Activity остановлена (время: \(now))")
            }
        }
    }
    
    private func forceStopAllActivities() {
        Task {
            let activities = Activity<TimeTrackingAttributes>.activities
            
            for activity in activities {
                await activity.end(
                    ActivityContent(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
            
            await MainActor.run {
                self.debugText = "✅ Все активности остановлены"
                self.activity = nil
                self.isTrackingTime = false
                self.startTime = nil
                self.timer.upstream.connect().cancel()
                print("🛑 Все активности остановлены")
            }
        }
    }
    
    private func restoreActivityState() {
        Task {
            let activities = Activity<TimeTrackingAttributes>.activities
            await MainActor.run {
                if !activities.isEmpty {
                    self.activity = activities.first
                    
                    if let contentState = self.activity?.content.state {
                        self.startTime = contentState.startTime
                        self.isTrackingTime = true
                        self.updateRemainingTime(startTime: contentState.startTime)
                        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                        self.debugText = "✅ Восстановлена активность\nЗапущена: \(self.formatDate(contentState.startTime))"
                        print("✅ Восстановлена активность. Запущена: \(self.formatDate(contentState.startTime))")
                    }
                } else {
                    // Если нет активностей, сбрасываем состояние
                    self.isTrackingTime = false
                    self.startTime = nil
                }
            }
        }
    }
    
    private func checkActiveActivities() {
        Task {
            let activities = Activity<TimeTrackingAttributes>.activities
            await MainActor.run {
                self.debugText = "Активных Live Activities: \(activities.count)"
                print("📊 Активных Live Activities: \(activities.count)")
            }
        }
    }
    
    private func checkLiveActivityCapability() {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            debugText = "✅ Live Activities поддерживаются"
            print("✅ Live Activities поддерживаются")
        } else {
            debugText = "⚠️ Live Activities не поддерживаются"
            print("⚠️ Live Activities не поддерживаются")
        }
    }
    
    // MARK: - Notification Permissions
    private func checkAndRequestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Запрашиваем разрешение
                center.requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings]) { granted, error in
                    if granted {
                        print("✅ Разрешение на уведомления получено")
                        self.registerNotificationCategories()
                    } else {
                        print("❌ Разрешение на уведомления не получено")
                    }
                }
            case .denied:
                print("⚠️ Уведомления запрещены пользователем")
            case .authorized, .provisional, .ephemeral:
                print("✅ Разрешение на уведомления уже есть")
                self.registerNotificationCategories()
            @unknown default:
                break
            }
        }
    }
    
    private func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Создаем действия для уведомлений
        let restartAction = UNNotificationAction(
            identifier: "RESTART_TIMER_ACTION",
            title: "Запустить снова",
            options: .foreground
        )
        
        let delayAction = UNNotificationAction(
            identifier: "DELAY_15MIN_ACTION",
            title: "Отложить на 15 мин",
            options: []
        )
        
        // Создаем категорию
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETED_CATEGORY",
            actions: [restartAction, delayAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "Таймер завершен",
            options: .customDismissAction
        )
        
        // Регистрируем категорию
        center.setNotificationCategories([timerCategory])
        print("✅ Категории уведомлений зарегистрированы")
    }
    
    private func resetAll() {
        forceStopAllActivities()
        settings.firstRecordDate = nil
        settings.lastRecordDate = nil
        settings.addIntervalMap = []
        settings.qtyCigarette = 1
        settings.baseTimerInterval = 30
        settings.baseTimerAdd = 15
        settings.setDifficulty(.easy)
        settings.currentIncreaseIndex = 0
        settings.initialCigaretteCount = 10
        settings.smokingHours = 12
        settings.hasReached24HourGoal = false
        
        hasCompletedInitialSetup = false
        debugText = "Все сброшено"
        print("🔄 Все данные сброшены")
    }
}

// MARK: - Initial Setup Sheet View
struct InitialSetupSheetView: View {
    @Binding var startHour: Int
    @Binding var endHour: Int
    @Binding var cigaretteCount: Int
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var calculatedInterval: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Время курения") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Первый перекур дня")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Picker("Начало", selection: $startHour) {
                            ForEach(0..<24) { hour in
                                Text("\(hour):00")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: startHour) { oldValue, newValue in
                            calculateInterval()
                        }
                    }
                    .padding(.vertical, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Последний перекур дня")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Picker("Конец", selection: $endHour) {
                            ForEach(0..<24) { hour in
                                Text("\(hour):00")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: endHour) { oldValue, newValue in
                            calculateInterval()
                        }
                    }
                    .padding(.vertical, 5)
                    
                    // Показываем информацию о времени
                    if startHour != endHour {
                        let smokingHours = calculateSmokingHours()
                        Text("Время курения: \(smokingHours) часов (\(startHour):00 - \(endHour):00)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Количество сигарет для расчета") {
                    Stepper(value: $cigaretteCount, in: 1...60) {
                        VStack(alignment: .leading) {
                            Text("Количество сигарет в день (для расчета)")
                            Text("\(cigaretteCount) шт.")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .onChange(of: cigaretteCount) { oldValue, newValue in
                        calculateInterval()
                    }
                    
                    Text("Это количество используется только для расчета начального интервала")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Section("Расчет интервала") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Базовый интервал между сигаретами:")
                            .font(.headline)
                        
                        if calculatedInterval > 0 {
                            let hours = Int(calculatedInterval) / 3600
                            let minutes = Int(calculatedInterval) / 60 % 60
                            
                            if hours > 0 {
                                Text("\(hours) ч \(minutes) мин")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text("\(minutes) минут")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Text("≈ \(Int(calculatedInterval)) секунд")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Divider()
                            
                            Text("План уменьшения:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("С \(cigaretteCount) сигарет до 1 сигареты за \(cigaretteCount - 1) шагов")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Затем переход на 24-часовой интервал")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("Введите данные для расчета")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button("Сохранить и продолжить") {
                        onComplete()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Начальная настройка")
            .navigationBarItems(trailing: Button("Отмена") {
                dismiss()
            })
            .onAppear {
                calculateInterval()
            }
        }
    }
    
    private func calculateSmokingHours() -> Int {
        if endHour >= startHour {
            return endHour - startHour
        } else {
            return (24 - startHour) + endHour
        }
    }
    
    private func calculateInterval() {
        guard cigaretteCount > 0 else {
            calculatedInterval = 0
            return
        }
        
        let smokingHours = calculateSmokingHours()
        let totalHours = smokingHours == 0 ? 24 : smokingHours
        let totalSeconds = TimeInterval(totalHours * 3600)
        let interval = totalSeconds / TimeInterval(cigaretteCount)
        
        // Округляем до ближайших 30 секунд и устанавливаем минимум 300 сек (5 мин)
        let rounded = (interval / 30).rounded() * 30
        calculatedInterval = max(rounded, 300)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var timerIntervalText = ""
    @State private var timerAddText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Информация") {
                    if let firstDate = settings.firstRecordDate {
                        HStack {
                            Text("Начало программы")
                            Spacer()
                            Text(formatDate(firstDate))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Следующее увеличение")
                        Spacer()
                        if let nextDate = settings.addIntervalMap.first {
                            Text(formatDate(nextDate))
                                .foregroundColor(.green)
                        } else {
                            Text("Не установлено")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Текущее количество сигарет")
                        Spacer()
                        Text("\(settings.qtyCigarette)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Прогресс увеличения")
                        Spacer()
                        Text("\(settings.currentIncreaseIndex)/\(settings.initialCigaretteCount)")
                            .foregroundColor(settings.hasReached24HourGoal ? .green : .orange)
                    }
                    
                    if settings.hasReached24HourGoal {
                        HStack {
                            Text("24-часовая цель")
                            Spacer()
                            Text("Достигнута! 🎉")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarItems(trailing: Button("Готово") {
                dismiss()
            })
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
