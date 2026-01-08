//
//  WatchClockView.swift
//  LccTools Watch App
//
//  Created by Bob Jacobsen on 2/18/25.
//

import SwiftUI
import os
import WatchConnectivity

class WatchClockModel: ObservableObject {
    // One of these is created in the main app
    // and referenced from the clock view.  This
    // lets the main app start and stop updating as
    // the Scene changes state.
    @Published var hour: String = "--"      // to be shown until the first update succeeds
    @Published var minute: String = "--"

    var timer: Timer?
    let context = ExtendedWCSessionDelegate.default.context

    let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "WatchClockModel")

    public func cancelUpdates() {
        logger.debug("cancelTimer")
        timer?.invalidate()  // stop the timer when not displayed
        timer = nil
    }

    public func startUpdates() {
        logger.debug("startTimer")
        // start the sequence of future updates
        let delay = 2.0  // 2 second per frame for energy use compromise
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
                self.hour = self.getHour()
                self.minute = self.getMinute()
            })
        }
        // and do an update right away without waiting for 1st timeout
        self.hour = self.getHour()
        self.minute = self.getMinute()
    }

    func getTime() -> Date {
        let now = Date()
        let run  = context.value["run"] as? Bool ?? true
        let lastTimeSet = context.value["lastTimeSet"] as? Date ?? now
        let timeLastSet = context.value["timeLastSet"] as? Date ?? now
        let rate = context.value["rate"] as? Double ?? 1.0
        if run {
            return lastTimeSet+(now-timeLastSet)*rate
        } else {
            return lastTimeSet
        }
    }
    internal var calendar: Calendar = Calendar.current
    public func getHour() -> String {
        return String(calendar.component(.hour, from: getTime()))
    }
    public func getMinute() -> String {
        return String(calendar.component(.minute, from: getTime()))
    }
}

struct WatchClockView: View {

    @ObservedObject var clockModel: WatchClockModel

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let scale = max(0.33, min( width / 158.0, height / 138.0))  // max prevents 0 value
            let fontsize = scale * 48.0
            let unitsize = scale * 64.0
            let offset = fontsize > 40.0 ? -16.0 : 0.0  // match timeUnitText below
            VStack {
                Text("Fast Time")
                HStack {
                    StopwatchUnit(timeUnit: clockModel.hour, timeUnitText: "HR", color: .blue, size: unitsize)
                    Text(":")
                        .font(.system(size: fontsize))
                        .offset(x: -3, y: offset)
                    StopwatchUnit(timeUnit: clockModel.minute, timeUnitText: "MIN", color: .blue, size: unitsize)
                }
                .padding()
                .onAppear {
                    clockModel.startUpdates()
                }.onDisappear {
                    clockModel.cancelUpdates()
                }
            }
        }
    }
}

/// Display one time unit field, i.e. hours. minutes or seconds
private struct StopwatchUnit: View {

    var timeUnit: String
    var timeUnitText: String
    var color: Color
    var size: CGFloat

    /// Time unit expressed as String with "0" as prefix if this is less than 10.
    var timeUnitStr: String {
        return timeUnit.count < 2 ? "0" + timeUnit : timeUnit
    }

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: size / 5.0)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .fill(color)
                    .frame(width: size, height: size, alignment: .center)

                HStack(spacing: 2) {
                    Text(timeUnitStr.characterAt(index: 0))
                        .font(.system(size: 0.64*size))
                        .frame(width: 0.38*size)
                    Text(timeUnitStr.characterAt(index: 1))
                        .font(.system(size: 0.64*size))
                        .frame(width: 0.38*size)
                }
            }
            if size > 40.0 {  // has to match offset computation above
                Text(timeUnitText)
                    .font(.system(size: 16))
            }
        }
    }
}

/// Provide a convenient, local single-character operation
private extension String {  // private to avoid confusing parse errors on other files uses of String
    /// Provide the character at a particular position
    /// - Parameter index: 0-based index of the desired character
    /// - Returns: String consisting of character at that index
    func characterAt(index: Int) -> String {
        let arrayString = Array(self)
        return String(arrayString[index])
    }
}

// provide a "-" subtraction operator for times:
//   Date - Date = TimeInterval
//  see: https://stackoverflow.com/questions/50950092/calculating-the-difference-between-two-dates-in-swift
extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

#Preview {
    WatchClockView(clockModel: WatchClockModel())
}
