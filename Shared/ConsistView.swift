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
    @ObservedObject var model: ThrottleModel

    @State private var selectedRConsistAddress = "<none>"

    @State private var selectedAddAddress = "<none>"

    var body: some View {
        VStack {
            Text("Select Consist Roster Entry")
            Picker("Roster Entries", selection: $selectedRConsistAddress) {
                ForEach(model.roster, id: \.self.label) {
                    Text($0.label)
                        .font(.largeTitle)
                }
            } //.pickerStyle(WheelPickerStyle())
            Divider()
            List {
                ConsistLocoView(name: "Some Loco")
                ConsistLocoView(name: "Another Loco")
                ConsistLocoView(name: "57L")
                ConsistLocoView(name: "Name in Roster that's Really Long")
            }
            // TODO: Define consist model and add display here
            // options are Rev Direction; Link F0; link Fn; maybe Hide - who are those linked _to_?
            Divider()
            Text("Select Locomotive to Add")
            HStack {
                Picker("Roster Entries", selection: $selectedRConsistAddress) {
                    ForEach(model.roster, id: \.self.label) {
                        Text($0.label)
                            .font(.largeTitle)
                    }
                } // .pickerStyle(WheelPickerStyle())
                StandardMomentaryButton(label: "Add", height: 35, font: .title2) {
                    
                }.frame(width: 70)
            }
        }
   }
}

struct ConsistLocoView : View {
    let name : String
    @State private var someBindingForToggle1 = false
    @State private var someBindingForToggle2 = false
    @State private var someBindingForToggle3 = false

    var body: some View {
        HStack {
            Spacer()
            Text(name)
                .frame(alignment: .center)
                .font(.title2)
            VStack{
                Toggle(isOn: $someBindingForToggle1) {
                    Label("Rev:", systemImage: "repeat")
                }
                Toggle(isOn: $someBindingForToggle2) {
                    Label("Link F0:", systemImage: "lightbulb")
                }
                Toggle(isOn: $someBindingForToggle3) {
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
        ConsistView(model: ThrottleModel(CanLink(localNodeID: NodeID(0))))
            .environmentObject(openlcblib)
    }
}
