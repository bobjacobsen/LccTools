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
        model = TurnoutModel(network: network)
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
                            model.setThrown(dccAddress)
                        }.frame(width: 80)
                        StandardMomentaryButton(label: "C", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setClosed(dccAddress)
                        }.frame(width: 80)
                   }
                }
            }
        }
    }
    
}

// TODO: move to separate file
// TODO: Add tracking of turnout state, including when others throw
import Foundation
class TurnoutModel : ObservableObject {
    @Published var addressArray : [Int] = []  // address-sorted form of addressSet
    var addressSet = Set<Int>()
    let network : OpenlcbNetwork
    
    init(network: OpenlcbNetwork) {
        self.network = network
    }
    func setClosed(_ address : Int) {
        processAddress(address)
        let eventID : UInt64 = UInt64(0x01_01_02_00_00_FE_00_00+address)
        network.produceEvent(eventID: EventID(eventID))
    }
    
    func setThrown(_ address : Int) {
        processAddress(address)
        let eventID : UInt64 = UInt64(0x01_01_02_00_00_FF_00_00+address)
        network.produceEvent(eventID: EventID(eventID))
    }
    func processAddress(_ address : Int) {
        if !addressSet.contains(address) {
            // only do this if needed to avoid unnecesary publishes
            addressSet.insert(address)
            addressArray = addressSet.sorted()
        }
    }
}

struct TurnoutView_Previews: PreviewProvider {
    static var previews: some View {
        TurnoutView(network: OpenlcbNetwork(sample: true))
    }
}
