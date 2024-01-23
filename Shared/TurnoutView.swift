//
//  TurnoutView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 10/3/22.
//

import OpenlcbLibrary
import SwiftUI

/// Show and allow control of  DCC turnouts.
struct TurnoutView: View {
    @State var dccAddress: Int = 1
    @State var macroAddress: Int = 1
    @ObservedObject var model: TurnoutModel
    var turnoutformatter = NumberFormatter()
    var macroformatter = NumberFormatter()

    init(network: OpenlcbNetwork) {
        turnoutformatter.minimum = 1
        turnoutformatter.maximum = 2040
        turnoutformatter.maximumFractionDigits = 0
        macroformatter.minimum = 1
        macroformatter.maximum = 65535
        macroformatter.maximumFractionDigits = 0
        model = network.turnoutModel0
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Enter Turnout Number (1-2040):")
                TextField("Number", value: $dccAddress, formatter: turnoutformatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Spacer()
            }
            HStack {
                StandardClickButton(label: "Throw", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setThrown(dccAddress)
                }
                StandardClickButton(label: "Close", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setClosed(dccAddress)
                }
            }
            StandardHDivider()
            
            // list of previous items
            List {
                ForEach(model.addressArray, id: \.self) { item in
                    HStack {
                        Spacer()
                        Text("\(String(item))")
                        StandardClickButton(label: "T", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setThrown(item)
                        }.frame(width: 60)
                        StandardClickButton(label: "C", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setClosed(item)
                        }.frame(width: 80)
                   }
               }
            }
            HStack {
                Spacer()
                Text("Enter Macro Number (1-65535):")
                TextField("Number", value: $macroAddress, formatter: macroformatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Spacer()
            }
            Spacer()
            HStack {
                StandardClickButton(label: "Set", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setMacro(macroAddress)
                }
            }
            StandardHDivider()
            
            // list of previous items
            List {
                ForEach(model.macroArray, id: \.self) { item in
                    HStack {
                        Spacer()
                        Text("\(String(item))")
                        StandardClickButton(label: "S", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setThrown(item)
                        }.frame(width: 60)
                    }
                }
            }
        }
    }
    
}

/// XCode preview for the TurnoutView
struct TurnoutView_Previews: PreviewProvider {
    static var previews: some View {
        TurnoutView(network: OpenlcbNetwork(sample: true))
    }
}
