//
//  ThrottleView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary
import os

// The complete throttle view, with both speed and function sections
struct ThrottleView: View {
    
    @ObservedObject var model: ThrottleModel
 
    @State private var isEditing = false    // for Sliders
    
    var bars : [ThrottleBar] = []
    let maxindex = 50                       // number of bars
    static let maxLength : CGFloat = 150.0  // length of horizontal bar area
    let maxSpeed = 100.0                    // TODO: Decide how to handle max speed - configurable?


    let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "ThrottleView")
    
    init(throttleModel : ThrottleModel) {
        self.model = throttleModel
        
        for index in 0...maxindex {
            // compute bar length from 0 to maxlength
            let length = CGFloat(ThrottleView.maxLength * pow(Double(maxindex - index) / Double(maxindex), 2.0))  // pow curves the progression
            let setSpeed = Float16( length/ThrottleView.maxLength*maxSpeed)
            bars.append(ThrottleBar(length: length, setSpeed: setSpeed))
        }
        
        logger.debug("init of ThrottleView")
    }
    
    var body: some View {
        VStack {
            StandardMomentaryButton(label: model.selectedLoco,
                                    height: 40){
                model.showingSelectSheet.toggle()
            }
            .sheet(isPresented: $model.showingSelectSheet) {  // show selection in a cover sheet
                LocoSelectionView(model: model) // shows full sheet
                // .presentationDetents([.fraction(0.25)]) // iOS16 feature
            }
            
            Slider(
                value: $model.speed,
                in: 0...100,
                onEditingChanged: { editing in
                    isEditing = editing
                }
            ) // Slider
            
            HStack {
                ThrottleSliderView(speed: $model.speed, bars: bars)
                FunctionsView(fnModels: model.fnModels)
            } // HStack
            
            Spacer()
            
            HStack {
                StandardMomentaryButton(label: "Stop", height: 40)
                {
                    model.speed = 0.0
                }

                HStack {
                    StandardToggleButton(label: "Rev", height: 40, select: $model.reverse)
                    {
                        let oldReverse = model.reverse
                        model.forward = false
                        model.reverse = true
                        if (!oldReverse) {
                            model.speed = 0.0
                        }
                    } // end Standard Button
                    StandardToggleButton(label: "Fwd", height: 40, select: $model.forward)
                    {
                        let oldForward = model.forward
                        model.forward = true
                        model.reverse = false
                        if (!oldForward) {
                            model.speed = 0.0
                        }
                    }
                }
            } // HStack of R/S/F
        } // VStack of entire View
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
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 3.0)
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
                    RoundedRectangle(cornerRadius: 2.0)
                        .frame(width: ThrottleView.maxLength - bar.length) // alignment: .leading, height: 15
                        .foregroundColor(speed >= bar.setSpeed ? .blue : .green)
                        .opacity(0.2)
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

// the display of functions
struct FunctionsView : View {
    var fnModels : [FnModel]

    var body: some View {
        List {
            ClockView() // add a clock view as the top bar
            ForEach(fnModels, id: \.id) { fnModel in
                FnButtonView(model: fnModel)
            }
        }
    }
}

// The function button itself
struct FnButtonView : View {
    
    @ObservedObject var model : FnModel

    var body: some View {
        Button(action:{
            DispatchQueue.main.async{ // to avoid "publishing changes from within view updates is not allowed"
                if (!model.momentary) { model.pressed = !model.pressed }
            }
            // TODO: is a momentary press down/up being recorded?
            // https://developer.apple.com/forums/thread/131715
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .frame(alignment: .center)
                    .foregroundColor(!model.momentary && model.pressed ? .blue : .green) // TODO: blue while momentary pressed
                //
                
                Text("FN \(model.label)")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }.padding(.vertical, 0)
    }
}

struct LocoSelectionView : View {
    @ObservedObject var model : ThrottleModel

    // TODO: When you come back to this View with a throttle selected, the selected loco should show in the Picker
    // TODO: Picker needs to display S/L - where does it get it?
    @State var address  = ""
    @State var addressForm  = 1
    @State private var selectedRosterAddress = "<none>"    
 
    let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "LocoSelectionView")

    var body: some View {
        VStack {
            Text("Select Locomotive")
                .font(.largeTitle)
            
            Divider()
            
            VStack {
                // Top section is for selecting from roster
                
                Text("Roster Entry:")
                    .font(.title)
                Picker("Roster Entries", selection: $selectedRosterAddress) {
                    ForEach(model.roster, id: \.self.label) {
                        Text($0.label)
                            .font(.largeTitle)
                    }
                }   // .pickerStyle(SegmentedPickerStyle())
                //.pickerStyle(MenuPickerStyle())  // default seems to be menu style here
                .pickerStyle(WheelPickerStyle())
                
                StandardMomentaryButton(label: "Select", height: 40){
                    logger.debug("upper select with \(selectedRosterAddress, privacy:.public)")
                    // TODO: Get the actual node ID from the RosterEntry
                    let idNumber = UInt64(selectedRosterAddress) ?? 0
                    model.startSelection(idNumber)
                }.disabled(selectedRosterAddress == "<none>")
            }
            
            Divider()
            
            // Bottom section is for selection by entering address
            
            VStack {
                Text("DCC Address:")
                    .font(.title)
                
                TextField("Enter address...", text: $address)
                    .font(.title)
                    .fixedSize()  // limit size to something reasonable
                
                Picker(selection: $addressForm, label: Text("DCC Address Form:")) { // DCC long/short picker
                    Text("Long").tag(1)
                    Text("Short").tag(2)
                }
                .font(.title)
                .pickerStyle(SegmentedPickerStyle())
                // .pickerStyle(.radioGroup)        // macOS only
                //.horizontalRadioGroupLayout()     // macOS only

                StandardMomentaryButton(label: "Select", height: 40){
                    logger.debug("lower select with \(address, privacy:.public) form: \(addressForm, privacy: .public)")
                    let idNumber = UInt64(address) ?? 0
                    model.startSelection(idNumber, forceLongAddr: (addressForm == 1))
                }.disabled(Int(address)==nil) // disable select if input can't be parsed
                
                Spacer()
                
                Text("Swipe down to close")
            }
        }
    }
}



struct ThrottleView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbLibrary(sample: true)
    static var previews: some View {
        ThrottleView(throttleModel: ThrottleModel(CanLink(localNodeID: NodeID(0))))
            .environmentObject(openlcblib)
    }
}
