//
//  ConsistView.swift
//
//  Created by Bob Jacobsen on 8/1/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display and allow editing of a locomotive consist.
///
/// Works through OpenlcbLibrary/ConsistModel.
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
                }
            }
            .onChange(of: selectedConsistAddress) { _ in
                consistModel.forLoco = selectionModel.getRosterEntryNodeID(from: selectedConsistAddress)
                consistModel.fetchConsist()
            }
            
            StandardHDivider()
            
            List {
                ForEach(consistModel.consist, id: \.self.id) { entry in
                    ConsistLocoView(
                        consistModel: consistModel,
                        entry: entry,
                        name: selectionModel.getRosterEntryName(from: entry.childLoco),
                        reverse: entry.reverse,
                        echoF0: entry.echoF0,
                        echoFn: entry.echoFn,
                        hidden: entry.hide
                    )
                    
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            () in self.deleteLoco(entry)
                        } label: {
                            Text("Delete")
                        }
                    }
                    StandardHDivider()
                }
            }
            
            Text("Swipe Left to Remove")
            
            StandardHDivider()
            
            Text("Select Locomotive to Add")
            
            HStack {
                Picker("Roster Entries", selection: $selectedAddAddress) {
                    ForEach(selectionModel.roster, id: \.self.label) {
                        Text($0.label)
                    }
                }
                
                // This button should be smaller to match picker box
                StandardClickButton(label: "Add", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    consistModel.addLocoToConsist(add: selectionModel.getRosterEntryNodeID(from: selectedAddAddress))
                }.disabled(disableAddButton()).frame(width: 70)
                
            }
        }
    }
    
    func deleteLoco(_ entry: ConsistModel.ConsistEntryModel ) {
        consistModel.removeLocoFromConsist(remove: entry.childLoco)
    }
    
    func disableAddButton() -> Bool {
        return selectedAddAddress == "<None>" || selectedConsistAddress == "<None>" || selectedAddAddress == selectedConsistAddress
    }
    
    struct ConsistLocoView: View {
        let consistModel: ConsistModel
        let entry: ConsistModel.ConsistEntryModel
        let name: String
        @State private var reverse: Bool
        @State private var echoF0: Bool
        @State private var echoFn: Bool
        @State private var hidden: Bool
        
        init(consistModel: ConsistModel, entry: ConsistModel.ConsistEntryModel, name: String,
             reverse: Bool, echoF0: Bool, echoFn: Bool, hidden: Bool) {
            self.consistModel = consistModel
            self.entry = entry
            self.name = name
            
            self.reverse = reverse
            self.echoF0 = echoF0
            self.echoFn = echoFn
            self.hidden = hidden
        }
        
        var body: some View {
            if !hidden {  // don't display hidden consist entries
                HStack {
                    
                    Spacer() // force presentation to right side
                    
                    Text(name)
                        .frame(alignment: .center)
                        .font(.title2)
                    
                    VStack {
                        Toggle(isOn: $reverse) {
                            Label("Rev:", systemImage: "repeat")
                        }.toggleStyle(.switch)
                            .onChange(of: reverse) { _ in
                                changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                            }
                        Toggle(isOn: $echoF0) {
                            Label("Link F0:", systemImage: "lightbulb")
                        }.toggleStyle(.switch)
                            .onChange(of: echoF0) { _ in
                                changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                            }
                        Toggle(isOn: $echoFn) {
                            Label("Link Fn:", image: "lightbulb.2") // only available as systemimage
                                                                    // starting in iOS 16, macOS 13
                                                                    // so we provide local copy
                        }.toggleStyle(.switch)
                            .onChange(of: echoFn) { _ in
                                changingToggle(reverse: reverse, echoF0: echoF0, echoFn: echoFn)
                            }
                    }.frame(width: 80, height: 120)
                        .labelStyle(.iconOnly)
                }
            }
        }
        
        func changingToggle(reverse: Bool, echoF0: Bool, echoFn: Bool) {
            consistModel.resetFlags(on: entry.childLoco, reverse: reverse,
                                    echoF0: echoF0, echoFn: echoFn, hide: false)
                                    // `hide` always false if loco is visible
        }
    }
}

/// XCode preview for the ConsistView
struct ConsistView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        let consistModel = ConsistModel(linkLayer: LinkLayer(NodeID(100)))
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
