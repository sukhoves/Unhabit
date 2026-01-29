//
//  Unhabit_widget.swift
//  Unhabit_widget
//
//  Created by Evgenii Sukhov on 16.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Tutorial_Widget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            VStack(spacing: 10) {
                Text("До перекура:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let now = Date()
                let endTime = context.state.endTime
                
                if endTime > now {
                    // Таймер обратного отсчета
                    Text(endTime, style: .timer)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                } else {
                    // Таймер завершен
                    Text("Готово!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                        Text("Старт: \(formatTime(context.state.startTime))")
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "number.circle.fill")
                        Text("Количество: ×\(context.state.qtyCigarette)")
                    }
                    .font(.caption)
                }
                .foregroundColor(.primary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedRegionView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    BottomInfoView(context: context)
                }
            } compactLeading: {
                
            } compactTrailing: {
                
            } minimal: {
    
            }
        }
    }
    
    private func timerColor(endTime: Date) -> Color {
        let remainingTime = endTime.timeIntervalSince(Date())
        if remainingTime <= 60 {
            return .red
        } else if remainingTime <= 300 {
            return .orange
        } else {
            return .white
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Expanded Region View
struct ExpandedRegionView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    
    var body: some View {
        VStack {
            Text("До следующего перекура")
                .font(.caption)
                .foregroundColor(.gray)
            
            let now = Date()
            let endTime = context.state.endTime
            
            if endTime > now {
                Text(endTime, style: .timer)
                    .font(.title.bold())
                    .monospacedDigit()
                    .foregroundColor(timerColor(endTime: endTime))
            } else {
                Text("Готово!")
                    .font(.title.bold())
                    .foregroundColor(.green)
            }
        }
    }
    
    private func timerColor(endTime: Date) -> Color {
        let remainingTime = endTime.timeIntervalSince(Date())
        if remainingTime <= 60 {
            return .primary
        } else if remainingTime <= 300 {
            return .primary
        } else {
            return .primary
        }
    }
}

// MARK: - Bottom Info View
struct BottomInfoView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Старт:")
                    .font(.caption2)
                Text(formatTime(context.state.startTime))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "number.circle")
                    .font(.caption2)
                Text("×\(context.state.qtyCigarette)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.secondary)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Leading View
struct CompactLeadingView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    
    var body: some View {
        Image(systemName: "timer")
            .foregroundColor(.blue)
    }
}

// MARK: - Compact Trailing View
struct CompactTrailingView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    
    var body: some View {
        let now = Date()
        let endTime = context.state.endTime
        
        if endTime > now {
            // Показываем оставшиеся минуты в компактном виде
            let remainingMinutes = Int(endTime.timeIntervalSince(now) / 60)
            Text("\(remainingMinutes)m")
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.white)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption2)
        }
    }
}

// MARK: - Minimal View
struct MinimalView: View {
    var body: some View {
        Image(systemName: "timer")
            .foregroundColor(.blue)
            .font(.caption2)
    }
}
