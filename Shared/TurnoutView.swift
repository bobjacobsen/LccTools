//
//  TurnoutView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 10/3/22.
//

import OpenlcbLibrary
import SwiftUI

/// Show and allow control of  DCC turnouts
struct TurnoutView: View {
    @State var dccAddress : Int = 1
    @ObservedObject var model : TurnoutModel
    var formatter = NumberFormatter()
    
    init(network : OpenlcbNetwork) {
        formatter.minimum = 1
        formatter.maximum = 2048
        formatter.maximumFractionDigits = 0
        model = network.turnoutModel0
    }
    
    var body: some View {
        VStack {
            Text("Enter Turnout Number (1-2048):")
            TextField("Turnout Number", value: $dccAddress, formatter: formatter)
            HStack {
                StandardMomentaryButton(label: "Throw", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setThrown(dccAddress)
                }
                StandardMomentaryButton(label: "Close", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setClosed(dccAddress)
                }
            }
            StandardHDivider()
            
            // list of previous items
            List() {
                ForEach(model.addressArray, id: \.self) { item in
                    HStack {
                        Spacer()
                        Text("\(String(item))")
                        StandardMomentaryButton(label: "T", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setThrown(item)
                        }.frame(width: 60)
                        StandardMomentaryButton(label: "C", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setClosed(item)
                        }.frame(width: 80)
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
