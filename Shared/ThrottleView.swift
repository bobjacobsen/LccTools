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
struct ThrottleView: View {  // TODO: Add useful stuff to make this a real throttle
    
    @ObservedObject var model: ThrottleModel
 
    @State private var isEditing = false    // for Sliders
    @State private var showingSelectSheet = false // // TODO: Connect to whether a loco is selected
    
    /// 1 scale mph in meters per second for the speed commands.
    /// The screen works in MPH; the model works in meters/sec
    static let MPH_to_mps = 0.44704

    var bars : [ThrottleBar] = []
    let maxindex = 50                       // number of bars
    static let maxLength : CGFloat = 150.0  // length of horizontal bar area
    let maxSpeed = 100.0 / MPH_to_mps       // TODO: Decide how to handle max speed - configurable?


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
                showingSelectSheet.toggle()
            }
            .sheet(isPresented: $showingSelectSheet) {  // show selection in a cover sheet
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
            
            Slider(
                value: $model.speed,
                in: 0...100,
                onEditingChanged: { editing in
                    isEditing = editing
                }
            ) // Slider
            
            HStack {
                StandardToggleButton(label: "Reverse", height: 40, select: $model.reverse)
                {
                    if (!model.reverse) {
                        model.speed = 0
                    }
                    model.forward = false
                    model.reverse = true
                } // end Standard Button
                StandardMomentaryButton(label: "Stop", height: 40)
                {
                    model.speed = 0.0
                }
                StandardToggleButton(label: "Forward", height: 40, select: $model.forward)
                {
                    if (!model.forward) {
                        model.speed = 0
                    }
                    model.forward = true
                    model.reverse = false
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
            ClockView() // add a clock view as the top bar  // TODO: tune clock appearance here
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
            if (!model.momentary) { model.pressed = !model.pressed }
            // TODO: is a momentary press down/up being recorded?
            // https://developer.apple.com/forums/thread/131715
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .frame(alignment: .center) // width: 120, height: 50,
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

    @State var address  = ""
    @State var addressForm  = 1
    @State private var selectedAddress = ""  // TODO: should be initialized to an entry
 
    let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "LocoSelectionView")

    var body: some View {
        VStack {
            Text("Select Locomotive")
                .font(.title)
            
            Text("Roster Entry")
            Picker("Roster Entries", selection: $selectedAddress) {
                ForEach(model.roster, id: \.self.label) {
                    Text($0.label)
                        .font(.largeTitle)
                }
            }   //.pickerStyle(SegmentedPickerStyle())
            //.pickerStyle(MenuPickerStyle())  // default seems to be menu style here
            //.pickerStyle(WheelPickerStyle())
            
            Button("Select"){
                logger.debug("upper select with \(selectedAddress, privacy:.public)")
                let idNumber = UInt64(selectedAddress) ?? 0
                model.startSelection(NodeID(idNumber))
            }
            
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
                Button("Select"){
                    logger.debug("lower select with \(address, privacy:.public)")
                    let idNumber = UInt64(address) ?? 0
                    model.startSelection(NodeID(idNumber))
                }
                Spacer()
                Text("Swipe down to close")
            }
        }
    }
}

struct ThrottleView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbLibrary(sample: true)
    static var previews: some View {
        ThrottleView(throttleModel: ThrottleModel(nil))
            .environmentObject(openlcblib)
    }
}
