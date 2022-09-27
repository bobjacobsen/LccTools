//
//  ClockView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/28/22.
//

import SwiftUI
import OpenlcbLibrary
import os

// This works by timer-based periodic refresh of hours/minutes/seconds @State variables from the underlying Clock instance

/// Display the LCC fast clock
///
/// Sizes itself to fill the given space.
struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b

    private static let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ClockView")

    @EnvironmentObject var openlcblib : OpenlcbNetwork {
        didSet(oldvalue) {
            ClockView.logger.info("EnvironmentObject clockModel0 did change")
        }
    }
    
    @State private var isRunning = false // will be updated when we first hear from clock
    
    @State private var hours : Int = 0
    
    @State private var minutes : Int = 0
    
    @State private var seconds : Int = 0

    /// Reload time values periodically
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let scale = max(0.33, min( width / 330.0, height / 90.0))  // max prevents 0 value on Mac
            let fontsize = scale * 48.0
            let unitsize = scale * 75.0
            let offset = fontsize > 40.0 ? -18.0 : 0.0
            let spacing = scale * 5.0
            VStack {
                Spacer()
                HStack(spacing: spacing) {
                    Spacer()
                    StopwatchUnit(timeUnit: hours, timeUnitText: "HR", color: .blue, size: unitsize)
                    Text(":")
                        .font(.system(size: fontsize))
                        .offset(y: offset)
                    StopwatchUnit(timeUnit: minutes, timeUnitText: "MIN", color: .blue, size: unitsize)
                    Text(":")
                        .font(.system(size: fontsize))
                        .offset(y: offset)
                    StopwatchUnit(timeUnit: seconds, timeUnitText: "SEC", color: .blue, size: unitsize)
                    Spacer()
                }.frame(alignment: .center)
                .onAppear {                    
                    let delay = 1.0/12.0  // 12fps for energy use compromise
                    timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
                        let date = openlcblib.clockModel0.getTime()
                        hours = openlcblib.clockModel0.getHour(date)
                        minutes = openlcblib.clockModel0.getMinute(date)
                        seconds = openlcblib.clockModel0.getSecond(date)
                    })
                }.onDisappear {
                    timer?.invalidate()  // stop the timer when not displayed
                }
                Spacer()
            }.frame(alignment: .center)
        } // end GeometryReader
    } // end body
}

// display one time unit field, i.e. hours. minutes or seconds
struct StopwatchUnit: View {
    
    var timeUnit: Int
    var timeUnitText: String
    var color: Color
    var size: CGFloat
    
    /// Time unit expressed as String.
    /// - Includes "0" as prefix if this is less than 10.
    var timeUnitStr: String {
        let timeUnitStr = String(timeUnit)
        return timeUnit < 10 ? "0" + timeUnitStr : timeUnitStr
    }
    
    var body: some View {
        
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: size / 5.0)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .fill(color)
                    .frame(width: size, height: size, alignment: .center)
                
                HStack(spacing: 2) {
                    Text(timeUnitStr.substring(index: 0))
                        .font(.system(size: 0.64*size))
                        .frame(width: 0.38*size)
                    Text(timeUnitStr.substring(index: 1))
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

private extension String {  // private to avoid confusing parse errors on other file's uses of substring
    func substring(index: Int) -> String {
        let arrayString = Array(self)
        return String(arrayString[index])
    }
}

struct ClockView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        ClockView()
            .environmentObject(openlcblib)
    }
}
