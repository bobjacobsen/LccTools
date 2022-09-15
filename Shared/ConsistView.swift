//
//  ConsistView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 8/1/22.
//

import SwiftUI
import OpenlcbLibrary
import os

struct ConsistView: View {
    @ObservedObject var consistModel: ConsistModel
    @ObservedObject var selectionModel: ThrottleModel
    
    @State private var selectedConsistAddress = "<None>"
    
    @State private var selectedAddAddress = "<None>"
    
    var body: some View {
        VStack {
            Text("Select Consist Roster Entry")
            
            Picker("Roster Entries", selection: $selectedConsistAddress) {
                ForEach(selectionModel.roster, id: \.self.label) {
                    Text($0.label)
                        .font(.largeTitle)
                }
            } //.pickerStyle(WheelPickerStyle())
            .onChange(of: selectedConsistAddress) { value in
                consistModel.forLoco = selectionModel.getRosterEntryNodeID(from: selectedConsistAddress)
                consistModel.fetchConsist()
            }

            Divider()

            List {
                ForEach(consistModel.consist, id: \.self.id) {
                    ConsistLocoView(
                        consistModel: consistModel,
                        entry: $0,
                        name: selectionModel.getRosterEntryName(from: $0.childLoco),
                        reverse: $0.reverse,
                        echoF0: $0.echoF0,
                        echoFn: $0.echoFn
                    )
                }
            }

            Divider()

            Text("Select Locomotive to Add")

            HStack {
                Picker("Roster Entries", selection: $selectedAddAddress) {
                    ForEach(selectionModel.roster, id: \.self.label) {
                        Text($0.label)
                            .font(.largeTitle)
                    }
                } // .pickerStyle(WheelPickerStyle())
                // TODO: must disable button (onChange above) if address <None> or same as consist address
                StandardMomentaryButton(label: "Add", height: 35, font: .title2) {
                    consistModel.addLocoToConsist(add: selectionModel.getRosterEntryNodeID(from: selectedAddAddress))
                }.disabled(disableAddButton()).frame(width: 70)
            }
            
        }
    }
    
    func disableAddButton() -> Bool {
        return selectedAddAddress == "<None>" || selectedConsistAddress == "<None>" || selectedAddAddress == selectedConsistAddress
    }
}

struct ConsistLocoView : View {
    let consistModel : ConsistModel
    let entry : ConsistModel.ConsistEntryModel
    let name : String
    @State private var reverse : Bool
    @State private var echoF0  : Bool
    @State private var echoFn  : Bool
    
    init(consistModel : ConsistModel, entry : ConsistModel.ConsistEntryModel, name : String,
         reverse : Bool, echoF0 : Bool, echoFn : Bool) {
        self.consistModel = consistModel
        self.entry = entry
        self.name = name

        self.reverse = reverse
        self.echoF0 = echoF0
        self.echoFn = echoFn
    }
    
    var body: some View {
        HStack {
            StandardMomentaryButton(label: "Del", height: 35, font: .title2) {
                consistModel.removeLocoFromConsist(remove: entry.childLoco)
                // TODO: (if needed) refresh consist ala Add
            }.frame(width: 60)
            Spacer()
            Text(name)
                .frame(alignment: .center)
                .font(.title2)
            VStack{
                Toggle(isOn: $reverse) {
                    Label("Rev:", systemImage: "repeat")
                }
                .onChange(of: reverse) { value in
                    changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                }
                Toggle(isOn: $echoF0) {
                    Label("Link F0:", systemImage: "lightbulb")
                }
                .onChange(of: echoF0) { value in
                    changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                }
                Toggle(isOn: $echoFn) {
                    Label("Link Fn:", image: "lightbulb.2") // only available as systemimage in iOS 16, macOS 13
                }
                .onChange(of: echoFn) { value in
                    changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                }
            }.frame(width: 80)
                .labelStyle(.iconOnly)
        }
    }
    
    func changingToggle(reverse : Bool, echoF0 : Bool, echoFn : Bool) {
        consistModel.resetFlags(on: entry.childLoco, reverse: reverse, echoF0: echoF0, echoFn: echoFn)
    }
    
}

struct ConsisteView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbLibrary(sample: true)
    static var previews: some View {
        let consistModel = ConsistModel(linkLayer : LinkLayer(NodeID(100)))
        consistModel.forLoco = NodeID(200)
        consistModel.consist.append(ConsistModel.ConsistEntryModel(childLoco: NodeID(201)))
        consistModel.consist.append(ConsistModel.ConsistEntryModel(childLoco: NodeID(202)))
        return ConsistView(
            consistModel: consistModel,
            selectionModel: ThrottleModel(CanLink(localNodeID: NodeID(0)))
        )
            .environmentObject(openlcblib)
    }
}
