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

// TODO: take the running state from the clock when first shown
// TODO: Decide if there's a Run/Stop button and if so what it does

struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b

    let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "ClockView")

    @EnvironmentObject var openlcblib : OpenlcbLibrary {
        didSet(oldvalue) {
            logger.info("EnvironmentObject clock0 did change")
        }
    }
    
    @State private var isRunning = false  // TODO: This isn't connected to underlying clock state (coming or going)
    
    @State private var hours : Int = 0
    
    @State private var minutes : Int = 0
    
    @State private var seconds : Int = 0

    /// Reload time values periodically
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                StopwatchUnit(timeUnit: hours, timeUnitText: "HR", color: .blue)
                Text(":")
                    .font(.system(size: 48))
                    .offset(y: -18)
                StopwatchUnit(timeUnit: minutes, timeUnitText: "MIN", color: .blue)
                Text(":")
                    .font(.system(size: 48))
                    .offset(y: -18)
                StopwatchUnit(timeUnit: seconds, timeUnitText: "SEC", color: .blue)
            }
            
            HStack {
                Button(action: {
                    if isRunning{
                        timer?.invalidate()
                    } else {
                        let delay = max( 0.0833, 1.0 / openlcblib.clock0.rate / 1.25) // no more than 12fps for energy use
                        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
                            let date = openlcblib.clock0.getTime()
                            hours = openlcblib.clock0.getHour(date)
                            minutes = openlcblib.clock0.getMinute(date)
                            seconds = openlcblib.clock0.getSecond(date)
                        })
                    }
                    isRunning.toggle()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15.0)
                            .frame(width: 120, height: 50, alignment: .center)
                            .foregroundColor(isRunning ? .green : .red)
                        
                        Text(isRunning ? "Stop" : "Start")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: {
                    // TODO: What does "Reset" do? Need a different button here?
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15.0)
                            .frame(width: 120, height: 50, alignment: .center)
                            .foregroundColor(.gray)
                        
                        Text("Reset")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// display one time unit, i.e. hours or minutes
struct StopwatchUnit: View {
    
    var timeUnit: Int
    var timeUnitText: String
    var color: Color
    
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
                    .frame(width: 75, height: 75, alignment: .center)
                
                HStack(spacing: 2) {
                    Text(timeUnitStr.substring(index: 0))
                        .font(.system(size: 48))
                        .frame(width: 28)
                    Text(timeUnitStr.substring(index: 1))
                        .font(.system(size: 48))
                        .frame(width: 28)
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
