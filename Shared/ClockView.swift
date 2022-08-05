//
//  ClockView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/28/22.
//

import SwiftUI

struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b
    // TODO: Stops in background, see https://stackoverflow.com/questions/63765532/swiftui-how-to-run-a-timer-in-background
    // TODO: Connect to clock in OpenlcbLibrary
    
    /// Current progress time expresed in seconds
    @State private var progressTime = 236
    @State private var isRunning = false
    
    /// Computed properties to get the progressTime in hh:mm:ss format
    var hours: Int {
        progressTime / 3600
    }
    
    var minutes: Int {
        (progressTime % 3600) / 60
    }
    
    var seconds: Int {
        progressTime % 60
    }
    
    /// Increase progressTime each second
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
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                            progressTime += 1
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
                    progressTime = 0
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
    static var previews: some View {
        ClockView()
    }
}
