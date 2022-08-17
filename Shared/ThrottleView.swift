//
//  ThrottleView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import os

struct ThrottleView: View {  // TODO: Add useful stuff to make this a real throttle
    @State private var speed = 50.0         // for Sliders
    @State private var isEditing = false    // for Sliders
    
    @State private var forward = true   // TODO: get initial state from somewhere?
    @State private var reverse = false
    
    var bars : [ThrottleBar] = []
    let maxindex = 50
    let maxLength : CGFloat = 150.0     // TODO: Combine two maxLength definitions
    let maxSpeed = 100.0                // TODO: Decide how to handle max speed
    
    let maxFn = 28
    var fnLabels : [FnLabel] = []  // TODO: how associate these with state?
    
    let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "ThrottleView")
    
    init() {
        for index in 0...maxindex {
            // compute bar length from 0 to maxlength // TODO: Decide how to handle speed fn curve
            let length = CGFloat(maxLength * pow(Double(maxindex - index) / Double(maxindex), 2.0))  // pow curves the progression
            let setSpeed = length/maxLength*maxSpeed
            bars.append(ThrottleBar(length: length, setSpeed: setSpeed))
        }
        
        for index in 0...maxFn {
            // default fn labels are just the numbers
            fnLabels.append(FnLabel(label: "\(index)"))
        }
        
        logger.debug("init of ThrottleView")
    }
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: LocoSelectionView() ) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15.0)
                            .frame(height: 50, alignment: .center) // width: 120,
                            .foregroundColor(.green)
                        
                        Text("Engine 4407")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                } // Nav Link
                
                Slider(
                    value: $speed,
                    in: 0...100,
                    onEditingChanged: { editing in
                        isEditing = editing
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
                                    .frame(height: 50, alignment: .center) // width: 120,
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
                                    .frame(height: 50, alignment: .center) // width: 120,
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
                                    .frame(height: 50, alignment: .center) // width: 120,
                                    .foregroundColor(forward ? .blue : .green)
                                
                                Text("Forward")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        } // label
                    ) // Button
                } // HStack of R/S/F
            } // VStack of entire View
        }.navigationTitle("Throttle View")  // NavigationView
    } // body
} // ThrottleView

struct ThrottleSliderView : View {
    @Binding var speed : Double
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
    @Binding var speed : Double
    
    let maxLength : CGFloat = 150.0
    
    var body: some View {
        HStack {
            Button(action:{
                speed = bar.setSpeed
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
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.0)
                        .frame(width: maxLength - bar.length) // alignment: .leading, height: 15
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
    let setSpeed : Double
    let id = UUID()
}

// Data to construct a single function button
struct FnLabel {
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
            Text("Loco Selection View")
                .font(.title)
            
            Picker("Roster Entries", selection: $selectedAddress) {
                ForEach(roster, id: \.self) {
                    Text($0)
                        .font(.largeTitle)
                }
            }   //.pickerStyle(SegmentedPickerStyle())
                //.pickerStyle(MenuPickerStyle())  // default seems to be menu style here
                //.pickerStyle(WheelPickerStyle())
            
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
        }
    }
}

struct ThrottleView_Previews: PreviewProvider {
    static var previews: some View {
        ThrottleView()
    }
}
