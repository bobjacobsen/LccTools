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

    @State private var selectedConsistAddress = "<none>"

    @State private var selectedAddAddress = "<none>"

    var body: some View {
        VStack {
            Text("Select Consist Roster Entry")
            Picker("Roster Entries", selection: $selectedConsistAddress) {
                ForEach(selectionModel.roster, id: \.self.label) {
                    Text($0.label)
                        .font(.largeTitle)
                }
            } //.pickerStyle(WheelPickerStyle())
            StandardMomentaryButton(label: "Read Consist", height: 35, font: .title2) {
                consistModel.forLoco = selectionModel.getRosterEntryNodeID(from: selectedConsistAddress)
                consistModel.fetchConsist()
            }
            Divider()
            List {
                ForEach(consistModel.consist, id: \.self.id) {
                    ConsistLocoView(name: selectionModel.getRosterEntryName(from: $0.childLoco))
                }
            }
            // TODO: Define consist model and add display here
            // options are Rev Direction; Link F0; link Fn; maybe Hide - who are those linked _to_?
            Divider()
            Text("Select Locomotive to Add")
            HStack {
                Picker("Roster Entries", selection: $selectedAddAddress) {
                    ForEach(selectionModel.roster, id: \.self.label) {
                        Text($0.label)
                            .font(.largeTitle)
                    }
                } // .pickerStyle(WheelPickerStyle())
                StandardMomentaryButton(label: "Add", height: 35, font: .title2) {
                    // TODO deactivate button if selected loco is already in consist
                    consistModel.addLocoToConsist(add: selectionModel.getRosterEntryNodeID(from: selectedAddAddress))
                }.frame(width: 70)
            }
        }
   }
}

struct ConsistLocoView : View {
    let name : String
    @State private var bindingForReverse = false
    @State private var bindingForEchoF0  = false
    @State private var bindingForEchoFN  = false

    var body: some View {
        HStack {
            Spacer()
            Text(name)
                .frame(alignment: .center)
                .font(.title2)
            VStack{
                Toggle(isOn: $bindingForReverse) {
                    Label("Rev:", systemImage: "repeat")
                }
                Toggle(isOn: $bindingForEchoF0) {
                    Label("Link F0:", systemImage: "lightbulb")
                }
                Toggle(isOn: $bindingForEchoFN) {
                    Label("Link Fn:", image: "lightbulb.2") // only available as systemimage in iOS 16, macOS 13
                }
            }.frame(width: 80)
                .labelStyle(.iconOnly)
        }
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
