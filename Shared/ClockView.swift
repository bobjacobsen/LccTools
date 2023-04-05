//
//  ClockView.swift
//
//  Created by Bob Jacobsen on 6/28/22.
//

import SwiftUI
import OpenlcbLibrary
import os

// This works by timer-based periodic refresh of hours/minutes/seconds @State variables from the underlying Clock instance

// TODO: Do people want seconds on their fast clock?

/// Display the LCC fast clock
///
/// Sizes itself to fill the given space.
struct ClockView: View {
    // see https://medium.com/geekculture/build-a-stopwatch-in-just-3-steps-using-swiftui-778c327d214b
    
    private static let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ClockView")
    
    @EnvironmentObject var openlcblib: OpenlcbNetwork
    
    @State private var isRunning = false // will be updated when we first hear from clock
    
    @State private var hours: Int = 0
    
    @State private var minutes: Int = 0
    
    @State private var seconds: Int = 0
    
    /// Reload time values periodically
    @State private var timer: Timer?
        
    var body: some View {
        VStack {
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
                    if height > 30 {
                        StandardClickButton(label: "Clock Controls",
                                        height: SMALL_BUTTON_HEIGHT,
                                            font: SMALL_BUTTON_FONT) {
                            openlcblib.clockModel0.showingControlSheet.toggle()
                        }
                    }
                }.frame(alignment: .center)
            } // end GeometryReader
            .sheet(isPresented: $openlcblib.clockModel0.showingControlSheet) {  // show controls in a cover sheet
                ClockControlsSheet(model: openlcblib.clockModel0) // shows full sheet
                // .presentationDetents([.fraction(0.25)]) // iOS16 feature
            }
        }
    } // end body
    
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

struct ClockControlsSheet: View {
    
    var model: ClockModel

    @State var tempRunState: Bool = false

    let rateArray = Array(stride(from: 0, through: 30, by: 0.25))
    @State var tempSelectedRate = 1.0

    @State var tempHours = "00"
    @State var tempMinutes = "00"
    // no seconds in fast clock itself
    
    var body: some View {
        Text("Clock Controls")
        Spacer()
        HStack {
            Spacer()
            VStack {
                HStack {
                    Text("Running:")
                    Toggle("", isOn: $tempRunState)
                        .onAppear {
                            tempRunState = model.run
                        }
                        .onChange(of: tempRunState) { value in
                            model.setRunStateInMaster(to: value)
                        }
                    Spacer(minLength: 50)
                }
                HStack {
                    #if os(iOS)
                    Text("Rate:")
                    #endif
                    Picker("Rate", selection: $tempSelectedRate) {
                        ForEach(rateArray, id: \.self) {
                            Text(String(format: "%.2f", $0))
                        }
                    } // TODO: need to call model.setRateInMaster
                    #if os(iOS)
                    .pickerStyle(WheelPickerStyle())
                    #endif
                    .onAppear {
                        tempSelectedRate = model.rate
                    }
                    .onChange(of: tempSelectedRate) { value in
                        model.setRunRateInMaster(to: value)
                    }
                }.padding()

                HStack {
                    Text("Time:")
                    TextField("", text: $tempHours)
                        .fixedSize()
                    Text(":")
                    TextField("", text: $tempMinutes)
                        .fixedSize()
                    Spacer()
                    StandardClickButton(label: "Set",
                                        height: SMALL_BUTTON_HEIGHT,
                                        font: SMALL_BUTTON_FONT) {
                        // Send changed time via model, using same date as now
                        let currentDate = model.getTime()
                        // create a new Date from components
                        var dateComponents = DateComponents()
                        dateComponents.year = model.getYear(currentDate)
                        dateComponents.month = model.getMonth(currentDate)
                        dateComponents.day = model.getDay(currentDate)
                        // dateComponents.timeZone = currentDate.timeZone
                        dateComponents.hour = Int(tempHours)
                        dateComponents.minute = Int(tempMinutes)
                        dateComponents.second = Int(0)
                        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
                        let newDate = userCalendar.date(from: dateComponents)
                        model.setTimeInMaster(to: newDate!)

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
            model.showingControlSheet = false
        }
#else
        Text("Swipe down to close")
#endif
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
