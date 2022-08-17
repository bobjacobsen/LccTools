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

// TODO: Make display larger on iPad or in landscape mode
// See https://developer.apple.com/forums/thread/126878 for how to tell portrait from landscape

struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b

    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ClockView")

    @EnvironmentObject var openlcblib : OpenlcbLibrary {
        didSet(oldvalue) {
            logger.info("EnvironmentObject clock0 did change")
        }
    }
    
    let cutoff = 480.0 // min size for larger display, empirically determined from iPhone 12 Pro Max at 428
    
    @State private var isRunning = false  // TODO: This isn't connected to underlying clock state (coming or going)
    
    @State private var hours : Int = 0
    
    @State private var minutes : Int = 0
    
    @State private var seconds : Int = 0

    /// Reload time values periodically
    @State private var timer: Timer?
    
#if os(iOS) // to check for iPhone v iPad
    @Environment(\.horizontalSizeClass) var horizontalSizeClass : UserInterfaceSizeClass?
#endif

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Spacer()
                    StopwatchUnit(timeUnit: hours, timeUnitText: "HR", color: .blue, size: geometry.size.width > cutoff ? 175 : 75)
                    Text(":")
                        .font(.system(size: geometry.size.width > cutoff ? 112 : 48))
                        .offset(y: -18)
                    StopwatchUnit(timeUnit: minutes, timeUnitText: "MIN", color: .blue, size: geometry.size.width > cutoff ? 175 : 75)
                    Text(":")
                        .font(.system(size: geometry.size.width > cutoff ? 112 : 48))
                        .offset(y: -18)
                    StopwatchUnit(timeUnit: seconds, timeUnitText: "SEC", color: .blue, size: geometry.size.width > cutoff ? 175 : 75)
                    Spacer()
                }.frame(alignment: .center)
                .onAppear {
                    let delay = 1.0/12.0  // 12fps for energy use compromise
                    timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
                        let date = openlcblib.clock0.getTime()
                        hours = openlcblib.clock0.getHour(date)
                        minutes = openlcblib.clock0.getMinute(date)
                        seconds = openlcblib.clock0.getSecond(date)
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
                RoundedRectangle(cornerRadius: 15.0)
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
            
            Text(timeUnitText)
                .font(.system(size: 16))
        }
    }
}

extension String {
    func substring(index: Int) -> String {
        let arrayString = Array(self)
        return String(arrayString[index])
    }
}

struct ClockView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbLibrary(sample: true)
    static var previews: some View {
        ClockView()
            .environmentObject(openlcblib)
    }
}
