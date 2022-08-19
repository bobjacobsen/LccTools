//
//  ThrottleView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import os

struct ThrottleView: View {  // TODO: Add useful stuff to make this a real throttle
    @State private var speed : Float16 = 0.0  // for Sliders

    @State private var forward = true   // TODO: get initial state from somewhere?
    @State private var reverse = false
    
    @State private var isEditing = false    // for Sliders
    @State private var showingSelectSheet = true // initially shown to do selection
    
    var bars : [ThrottleBar] = []
    let maxindex = 50
    static let maxLength : CGFloat = 150.0
    let maxSpeed = 100.0                // TODO: Decide how to handle max speed
    
    let maxFn = 28
    var fnLabels : [FnModel] = []  // TODO: how associate these with state?
    
    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "ThrottleView")
    
    init() {
        for index in 0...maxindex {
            // compute bar length from 0 to maxlength // TODO: Decide how to handle speed fn curve
            let length = CGFloat(ThrottleView.maxLength * pow(Double(maxindex - index) / Double(maxindex), 2.0))  // pow curves the progression
            let setSpeed = Float16( length/ThrottleView.maxLength*maxSpeed)
            bars.append(ThrottleBar(length: length, setSpeed: setSpeed))
        }
        
        for index in 0...maxFn {
            // default fn labels are just the numbers
            fnLabels.append(FnModel(label: "\(index)"))
        }
        
        logger.debug("init of ThrottleView")
    }
    
    var body: some View {
            VStack {
                ZStack { // large-format button for loco selection
                    RoundedRectangle(cornerRadius: 15.0)
                        .frame(height: 50, alignment: .center)
                        .foregroundColor(.green)
                    Button("DCC 4407") {    // TODO: need to load current selection from state
                        showingSelectSheet.toggle()
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    // when clicked, show loco selection in a covering sheet
                    .sheet(isPresented: $showingSelectSheet) {  // show selection in a cover sheet
//                        if #available(iOS 16.0, *) {
//                            LocoSelectionView()
//                                .presentationDetents([.fraction(0.25)])
//                        } else {
                            // Fallback on earlier versions
                            LocoSelectionView() // shows full sheet
//                        }
                    }
                } // end ZStack button
                    
                Slider(
                    value: $speed,
                    in: 0...100,
                    onEditingChanged: { editing in
                        isEditing = editing
                        print ("isEditing \(isEditing) speed \(speed)")
                    }
                ) // Slider
                
                HStack {
                    ThrottleSliderView(speed: $speed, bars: bars)
                    
                    List {
                        ForEach(fnLabels, id: \.id) { fnLabel in
                            FnButtonView(fnLabel.label)
                        }
                    }
                    
                } // HStack
                
                Spacer()
                
                Slider(
                    value: $speed,
                    in: 0...100,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                ) // Slider
                
                HStack {
                    Button(
                        action: {
                            if (!reverse) {
                                speed = 0
                            }
                            forward = false
                            reverse = true
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15.0)
                                    .frame(height: 50, alignment: .center)
                                    .foregroundColor(reverse ? .blue : .green)
                                
                                Text("Reverse")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        } // label
                    ) // Button
                    Button(
                        action: {
                            speed = 0.0
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15.0)
                                    .frame(height: 50, alignment: .center)
                                    .foregroundColor(.green)
                                
                                Text("Stop")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        } // label
                    ) // Button
                    Button(
                        action: {
                            if (!forward) {
                                speed = 0
                            }
                            forward = true
                            reverse = false
                        },
                        label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15.0)
                                    .frame(height: 50, alignment: .center)
                                    .foregroundColor(forward ? .blue : .green)
                                
                                Text("Forward")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        } // label
                    ) // Button
                } // HStack of R/S/F
            } // VStack of entire View
//        }.navigationTitle("Throttle View")  // NavigationView
    } // body
} // ThrottleView

struct ThrottleSliderView : View {
    @Binding var speed : Float16
    var bars : [ThrottleBar]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(bars, id: \.id) { bar in
                ThrottleBarView(bar : bar, speed: $speed)
            }
        }
    } // body
} // ThrottleSliderView

// View a single bar in the ThrottleSliderView
struct ThrottleBarView : View {
    let bar : ThrottleBar
    @Binding var speed : Float16
        
    var body: some View {
        HStack {
            Button(action:{
                speed = bar.setSpeed
                print ("button sets speed \(speed)")
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.0)
                        .frame(width: bar.length) // height is computed automatically
                        .foregroundColor(speed >= bar.setSpeed ? .blue : .green)
                }
            } // label
            ) // Button
            .padding(.vertical, 0)
            .padding(.leading, 8)
            .padding(.trailing, -5)
            
            // add a transparent button to fill out rest of line
            Button(action:{
                speed = bar.setSpeed
                print ("button sets speed \(speed)")
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.0)
                        .frame(width: ThrottleView.maxLength - bar.length) // alignment: .leading, height: 15
                        .foregroundColor(speed >= bar.setSpeed ? .blue : .green)
                        .opacity(0.1)
                } // ZStack
            } // label
            ) // Button
            .padding(.vertical, 0)
            .padding(.horizontal, 0)
            
            Spacer() // align to left
            
        } // HStack
    } // body
} // Throttle Bar View

// Data for a single bar
struct ThrottleBar {
    let length: CGFloat
    let setSpeed : Float16
    let id = UUID()
}

// Data to construct a single function button
struct FnModel {
    let label : String
    let id = UUID()
}

// The function button itself
struct FnButtonView : View {
    @State var pressed = false      // true highlights button as down
    @State var momentary = false    // false makes button push on, push off
    let number: String
    init(_ number : String) {
        self.number = number
    }
    var body: some View {
        Button(action:{
            if (!momentary) { pressed = !pressed }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .frame(alignment: .center) // width: 120, height: 50,
                    .foregroundColor(!momentary && pressed ? .blue : .green)
                
                Text("FN \(number)")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }.padding(.vertical, 0)
    }
}

struct LocoSelectionView : View {
    @State var address  = ""
    @State var addressForm  = 1
    @State private var selectedAddress = "4137"

    var roster = ["4137", "2111", "This is a really long roster name", "99", "2114", "2115", "2116", "2117"]

    var body: some View {
        VStack {
            Text("Select Locomotive")
                .font(.title)
            
            Text("Roster Entry")
            Picker("Roster Entries", selection: $selectedAddress) {
                ForEach(roster, id: \.self) {
                    Text($0)
                        .font(.largeTitle)
                }
            }   //.pickerStyle(SegmentedPickerStyle())
            //.pickerStyle(MenuPickerStyle())  // default seems to be menu style here
            //.pickerStyle(WheelPickerStyle())
            
            Button("Select"){}
            
            Divider()
            
            VStack {
                HStack {
                    Text("DCC Address:")
                    Picker(selection: $addressForm, label: Text("DCC Address Form:")) {
                        Text("Long").tag(1)
                        Text("Short").tag(2)
                    }
                    // .pickerStyle(.radioGroup)        // macOS only
                    //.horizontalRadioGroupLayout()     // macOS only
                }
                TextField("Enter address...", text: $address)
                    .fixedSize()  // limit size to something reasonable
                Button("Select"){}
                Spacer()
                Text("Swipe down to close")
            }
        }
    }
}

struct ThrottleView_Previews: PreviewProvider {
    static var previews: some View {
        ThrottleView()
    }
}
