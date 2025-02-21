//
//  ClockView.swift
//
//  Created by Bob Jacobsen on 6/28/22.
//

import SwiftUI
import os
import OpenlcbLibrary

// This works by timer-based periodic refresh of hours/minutes/seconds @State variables from the underlying Clock instance
// TODO: Do people really want seconds on their fast clock?

/// Display the LCC fast clock.
///
/// Sizes itself to fill the given space.
struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b
    
    static let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ClockView")
    
    @EnvironmentObject var openlcblib: OpenlcbNetwork
    
    @State private var hours: Int = 0
    
    @State private var minutes: Int = 0
    
    @State private var seconds: Int = 0

    /// Show controls sheet
    @State var showSheet: Bool = false

    /// Reload time values periodically
    @State var timer: Timer?
        
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let scale = max(0.33, min( width / 330.0, height / 90.0))  // max prevents 0 value on Mac
                let fontsize = scale * 48.0
                let unitsize = scale * 75.0
                let offset = fontsize > 40.0 ? -18.0 : 0.0  // match timeUnitText below
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
                            if timer == nil {
                                timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
                                    let date = openlcblib.clockModel0.getTime()
                                    hours = openlcblib.clockModel0.getHour(date)
                                    minutes = openlcblib.clockModel0.getMinute(date)
                                    seconds = openlcblib.clockModel0.getSecond(date)
                                })
                            }
                            // make sure that a watch gets an initial status
                            openlcblib.clockModel0.updateCompanionApp()
                        }.onDisappear {
                            timer?.invalidate()  // stop the timer when not displayed
                            timer = nil
                        }
                    Spacer()
                    if height > 30 {
                        StandardClickButton(label: "Clock Controls",
                                            height: SMALL_BUTTON_HEIGHT,
                                            font: SMALL_BUTTON_FONT) {
                            showSheet.toggle()
                        }
                    }
                }.frame(alignment: .center)
            } // end GeometryReader
            .sheet(isPresented: $showSheet) {
                // controls cover sheet
                ClockControlsSheet(model: openlcblib.clockModel0) // shows full sheet
                // .presentationDetents([.fraction(0.25)]) // iOS16 feature
            }
        }
    } // end body
}

/// Display one time unit field, i.e. hours. minutes or seconds
private struct StopwatchUnit: View {
    
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

private struct ClockControlsSheet: View {
    /// Show controls sheet
    static let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ClockControlsSheet")

    @Environment(\.dismiss) private var dismiss
    
    var model: ClockModel
    
    @State var tempRunState: Bool = false
    
    let rateArray = Array(stride(from: 0.25, through: 30, by: 0.25))
    @State var tempSelectedRate = 1.0
    
    @State var tempHours = "00"
    @State var tempMinutes = "00"
    // no seconds in fast clock itself
    
    let timeSetFont = Font.largeTitle
    
    var body: some View {
        Text("Clock Controls")
        Spacer()
        HStack {
            Spacer()
            VStack {
                HStack {
                    Text("Running:")
                        .font(timeSetFont)
                    Toggle("", isOn: $tempRunState)
                        .onAppear {
                            tempRunState = model.run
                        }
                        .onChange(of: tempRunState) { value in
                            model.setRunStateInMaster(to: value)
                            model.run = value
                            // Send to watch companion app
                            model.updateCompanionApp()
                        }
                    Spacer(minLength: 50)
                }
                HStack {
#if os(iOS)
                    // macOS titles its Picker
                    Text("Rate:")
                        .font(timeSetFont)
#endif
                    Spacer()
                    Picker("Rate", selection: $tempSelectedRate) {
                        ForEach(rateArray, id: \.self) {
                            Text(String(format: "%.2f", $0))
                        }.font(timeSetFont)
                    } // TODO: need to call model.setRateInMaster
#if os(iOS)
                    .pickerStyle(WheelPickerStyle())
#endif
                    .onAppear {
                        tempSelectedRate = model.rate
                    }
                    .onChange(of: tempSelectedRate) { value in
                        model.setRunRateInMaster(to: value)
                        model.rate = value
                        // Send to watch companion app
                        model.updateCompanionApp()
                    }
                }.padding()
                
                HStack {
                    Text("Time:")
                        .font(timeSetFont)
                    TextField("", text: $tempHours)
                        .fixedSize()
                        .font(timeSetFont)
                    Text(":")
                        .font(timeSetFont)
                    TextField("", text: $tempMinutes)
                        .fixedSize()
                        .font(timeSetFont)
                    Spacer()
                    StandardClickButton(label: "Set",
                                        height: STANDARD_BUTTON_HEIGHT,
                                        font: STANDARD_BUTTON_FONT) {
                        // Update time in clock model
                        // We reload TextFields here in case the entered time was out of range
                        (tempHours, tempMinutes) = model.updateTime(hour: Int(tempHours) ?? 0, minute: Int(tempMinutes) ?? 0)
                        // Send to watch companion app
                        model.updateCompanionApp()
                        
                    }.onAppear {
                        tempHours = String(format: "%02d", model.getHour() )
                        tempMinutes = String(format: "%02d", model.getMinute() )
                    }.frame(width: 100)
                }
            }
            Spacer()
        }
        
        Spacer()
#if targetEnvironment(macCatalyst) || os(macOS)
        StandardClickButton(label: "Dismiss", font: SMALL_BUTTON_FONT) {
            dismiss()
        }
#else
        Text("Swipe down to close")
#endif
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

/// XCode preview for the ClockView
struct ClockView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        ClockView()
            .environmentObject(openlcblib)
    }
}
