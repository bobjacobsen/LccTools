//
//  ThrottleView.swift
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary
import os

/// The complete Throttle view, with both speed and function sections.
struct ThrottleView: View {
    
    @ObservedObject var model: ThrottleModel
 
    @State private var isEditing = false    // for Sliders
    
    fileprivate var bars: [ThrottleBar] = []

    let maxindex = 50       // number of bars - set with maxSpeed, throttle curve to have low bars ~ 1mph
    let maxSpeed = 126.0    // MPH, but mapped to speed step in DCC world; see Traction TN 4.1

    private static let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "ThrottleView")
    
    init(throttleModel: ThrottleModel) {
        self.model = throttleModel
        
        for index in 0...maxindex {
            // compute bar length from 0 to maxlength
            let fraction = CGFloat(pow(Double(maxindex - index) / Double(maxindex), 1.5))  // pow curves the progression
            let setSpeed = Float(fraction*maxSpeed)
            bars.append(ThrottleBar(fraction: fraction, setSpeed: setSpeed))
        }
        
        self.model.reloadRoster()
        ThrottleView.logger.debug("init of ThrottleView")
    }
    
    var body: some View {
        return VStack {
            StandardClickButton(label: model.selectedLoco) {
                model.showingSelectSheet.toggle()
            }
            .sheet(isPresented: $model.showingSelectSheet) {  // show selection in a cover sheet
                LocoSelectionView(model: model) // shows full sheet
                // .presentationDetents([.fraction(0.25)]) // iOS16 feature
            }
            
            Slider(
                value: $model.speed,
                in: 0...Float(maxSpeed),
                onEditingChanged: { editing in
                    isEditing = editing
                }
            ) // Slider
            
            HStack {
                ThrottleSliderView(speed: $model.speed, bars: bars)
                VStack {
                    Text(String(format: "Speed: %.1f", model.speed))
                    ClockView()
                        .frame(height: STANDARD_BUTTON_HEIGHT*1.33)
                    FunctionsView(fnModels: model.fnModels)
                }
            } // HStack
            
            Spacer()
            
            HStack {
                StandardClickButton(label: "Stop") {
                    model.speed = 0.0
                }

                HStack {
                    StandardToggleButton(label: "Rev", select: $model.reverse) {
                        let oldReverse = model.reverse
                        model.forward = false
                        model.reverse = true
                        if !oldReverse {
                            model.speed = 0.0
                        }
                    } // end Reverse Standard Button
                    StandardToggleButton(label: "Fwd", select: $model.forward) {
                        let oldForward = model.forward
                        model.forward = true
                        model.reverse = false
                        if !oldForward {
                            model.speed = 0.0
                        }
                    } // end Forward Standard Button
                } // HStack of R/F
            } // HStack of S / (R/F)
        } // VStack of entire View
    } // body
} // ThrottleView

// TODO: Throttle buttons should react to sliding over them, not just a press
/// Show a vertical column of bars that represents the throttle position
private struct ThrottleSliderView: View {
    @Binding var speed: Float
    var bars: [ThrottleBar]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            VStack(spacing: 0) {
                ForEach(bars, id: \.id) { bar in
                    ThrottleBarView(bar: bar, speed: $speed, maxWidth: width)
                }
            }
        }
    } // body
    
    /// View a single bar in the ThrottleSliderView
    struct ThrottleBarView: View {
        fileprivate let bar: ThrottleBar
        @Binding var speed: Float
        let maxWidth: CGFloat
        var body: some View {
            HStack {
                Button(action: {
                    speed = round(bar.setSpeed)
                }, // Action
                       label: {
                    RoundedRectangle(cornerRadius: 3.0)
                        .frame(width: bar.fraction*maxWidth) // height is computed automatically
                        .foregroundColor(speed >= bar.setSpeed ? .blue : .green)
                } // label
                ) // Button
                .buttonStyle(.borderless)  // for macOS
                .padding(.vertical, 0)
                .padding(.leading, 8)
                .padding(.trailing, -5)
                ._onButtonGesture { _ in // set the speed when first pressed, without waiting for a pull press & release
                    // TODO: on macOS, this waits for release
                    speed = bar.setSpeed
                } perform: {}
                
                // add a transparent button to fill out rest of line
                Button(action: {
                    speed = round(bar.setSpeed)
                }, // Action
                       label: {
                    RoundedRectangle(cornerRadius: 2.0)
                        .frame(width: maxWidth*(1.0 - bar.fraction))
                        .foregroundColor(speed >= bar.setSpeed ? .blue : .green)
                        .opacity(0.2)
                } // label
                ) // Button
                .buttonStyle(.borderless)  // for macOS
                .padding(.vertical, 0)
                .padding(.horizontal, 0)
                ._onButtonGesture { _ in // set the speed when first pressed, without waiting for a pull press & release
                    // TODO: on macOS, this waits for release
                    speed = bar.setSpeed
                } perform: {}
                
                Spacer() // align to left
                
            } // HStack
        } // body
    } // Throttle Bar View
} // ThrottleSliderView

/// Data for a single bar
///
/// Local, not part of model, because these together represent the `speed` value
private struct ThrottleBar {
    let fraction: CGFloat
    let setSpeed: Float
    let id = UUID()
}

/// Display the set of functions
private struct FunctionsView: View {
    var fnModels: [ThrottleModel.FnModel]
    
    var body: some View {
        List {
            ForEach(fnModels, id: \.id) { fnModel in
                FnButtonView(model: fnModel)
#if os(iOS)
                    .listRowSeparator(.hidden) // first supported in macOS 13, but not really necessary on macOS
                    .padding(.vertical, -4)
#endif
            }
        }.listStyle(PlainListStyle())
    }
    
    /// One function button itself
    struct FnButtonView: View {
        
        @ObservedObject var model: ThrottleModel.FnModel
        @State private var pressing = false
        
        var body: some View {
#if os(iOS)
            let font = model.label.count <= 10 ? (model.label.count <= 7 ? STANDARD_BUTTON_FONT : SMALL_BUTTON_FONT) : SMALLER_BUTTON_FONT
#else // macOS
            let font = STANDARD_BUTTON_FONT
#endif
            if !model.momentary {
                // toggle button case
                StandardToggleButton(label: model.label,
                                     font: font,
                                     select: $model.pressed) {
                    // on pressed
                    model.pressed = !model.pressed
                }
            } else {
                // momentary button case
                StandardMomentaryButton(label: model.label,
                                        font: font,
                                        down: {model.pressed = true},
                                        up: {model.pressed = false}
                )

            }
        }
    }
}

/// View for selecting a locomotive, intended for a separate page
struct LocoSelectionView: View {
    @ObservedObject var model: ThrottleModel
    
    @State var address  = ""
    @State var addressForm  = 1
    @State private var selectedRosterAddress = "<None>"
 
    private static let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "LocoSelectionView")
    
    var body: some View {

        VStack {
            Text("Select Locomotive")
                .font(.largeTitle)
            
            StandardHDivider()
            
            VStack {
                // Top section is for selecting from roster
                Text("Roster Entry:")
                    .font(.title)
                Picker("Roster Entries", selection: $selectedRosterAddress) {
                    ForEach(model.roster, id: \.self.label) {
                        Text($0.label)
                    }
                }
                #if os(iOS)
                    .pickerStyle(WheelPickerStyle())
                #endif
                
                StandardClickButton(label: "Select", font: .title) {
                    LocoSelectionView.logger.debug("upper select with \(selectedRosterAddress, privacy: .public)")
                    // search model.roster for matching entry to get nodeID
                    for rosterEntry in model.roster where rosterEntry.label == selectedRosterAddress {
                        model.startSelection(entry: rosterEntry)
                        break  // expect to always find this, don't do anything if not
                    }
                }.disabled(selectedRosterAddress == "<None>")
            } // end top section to select from roster
            
            StandardHDivider()
            
            VStack {
                // Bottom section is for selection by entering address
                Text("DCC Address:")
                    .font(.title)
                
                TextField("Enter address...", text: $address)
                    .font(.title)
                    .fixedSize()  // limit size to something reasonable
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
                
                Picker(selection: $addressForm, label: Text("DCC Address Form:")) { // DCC long/short picker
                    Text("Long").tag(1)
                    Text("Short").tag(2)
                }
                .font(.title)
                .pickerStyle(SegmentedPickerStyle())

                StandardClickButton(label: "Select", font: .title) {
                    LocoSelectionView.logger.debug("lower select with \(address, privacy: .public) form: \(addressForm, privacy: .public)")
                    let idNumber = UInt64(address) ?? 0
                    model.startSelection(address: idNumber, forceLongAddr: (addressForm == 1))
                }.disabled(Int(address)==nil) // disable select if input can't be parsed
                
                Spacer()
                
            } // end bottom section for selecting by address
#if targetEnvironment(macCatalyst) || os(macOS)
            StandardClickButton(label: "Dismiss", font: SMALL_BUTTON_FONT) {
                model.showingSelectSheet = false
            }
#else
            Text("Select or swipe down to close")
#endif
        }
    }
}

/// XCode preview for the ThrottleView
struct ThrottleView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        ThrottleView(throttleModel: ThrottleModel(CanLink(localNodeID: NodeID(0))))
            .environmentObject(openlcblib)
    }
}
