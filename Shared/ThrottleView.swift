//
//  ThrottleView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI

struct ThrottleView: View {  // TODO: Add useful stuff to make this a throttle
    @State private var speed = 50.0         // for Slider
    @State private var isEditing = false    // for Slider
    
    var bars : [ThrottleBar] = []
    let maxindex = 50
    let maxLength : CGFloat = 150.0   // TODO: Combine two maxLength definitions
    let maxSpeed = 100.0 // TODO: Decide how to handle speed fn, max speed
    
    let maxFn = 28
    var fnLabels : [FnLabel] = []
    
    init() {
        for index in 0...maxindex {
            // compute bar length from 0 to maxlength
            let length = CGFloat(maxLength * Double(maxindex - index) / Double(maxindex))
            let setSpeed = length/maxLength*maxSpeed
            bars.append(ThrottleBar(length: length, setSpeed: setSpeed))
        }

        for index in 0...maxFn {
            // default fn labels are just the numbers
            fnLabels.append(FnLabel(label: "\(index)"))
        }
        
        print("init of ThrottleView")
    }

    
    
    var body: some View {
        VStack {
            Button(action:{
                print("Locomotive Button")
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .frame(height: 50, alignment: .center) // width: 120,
                        .foregroundColor(.green)
                    
                    Text("Engine 4407")
                        .font(.title)
                        .foregroundColor(.white)
                }
            } // label
            ) // Button

            Slider(
                value: $speed,
                in: 0...100,
                onEditingChanged: { editing in
                    isEditing = editing
                }
            )
            HStack {
                ThrottleSliderView(speed: $speed, bars: bars)

                List {
                    ForEach(fnLabels, id: \.id) { fnLabel in
                        FnButtonView(fnLabel.label)
                    }
                }

            }
            Spacer()
            Slider(
                value: $speed,
                in: 0...100,
                onEditingChanged: { editing in
                    isEditing = editing
                }
            )

            
        }.navigationTitle("Throttle View")  // VStack
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
                print("Button speed \(bar.setSpeed)")
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
            
            // add a transparent button to fill out rest of line
            Button(action:{
                print("Button length \(bar.length)")
                speed = bar.setSpeed
            }, // Action
                   label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.0)
                        .frame(width: maxLength - bar.length) // alignment: .leading, height: 15
                        .opacity(0.0)
                } // ZStack
            } // label
            ) // Button
            .padding(.vertical, 0)
            
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

// Data for a single function button
struct FnLabel {
    let label : String
    let id = UUID()
}

// The function button itself
struct FnButtonView : View {
    let number: String
    init(_ number : String) {
        self.number = number
    }
    var body: some View {
        Button(action:{
            print("Function \(number) pressed")
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .frame(alignment: .center) // width: 120, height: 50,
                    .foregroundColor(.green)
                
                Text("FN \(number)")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }.padding(.vertical, 0)
    }
}



struct ThrottleView_Previews: PreviewProvider {
    static var previews: some View {
        ThrottleView()
    }
}
