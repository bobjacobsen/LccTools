//
//  NodeSummaryView.swift
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display of the details of a single node.
/// 
/// Invoked from e.g. NodeListNavigationView
struct NodeSummaryView: View {
    var displayNode: Node
    let network: OpenlcbNetwork
 
    init(displayNode : Node, network: OpenlcbNetwork) {
        self.displayNode = displayNode
        self.network = network
    }
    
    var body: some View {
        VStack {
            List {
                Text(displayNode.name).font(.title)
                Text(displayNode.snip.userProvidedDescription)
                Text(displayNode.id.description) // nodeID
                Text(displayNode.snip.modelName)
                Text(displayNode.snip.manufacturerName)
                Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
            }.refreshable {
                refresh()
            }
            HStack {
                                    
                if displayNode.pipSet.contains(.CONFIGURATION_DESCRIPTION_INFORMATION)
                    && displayNode.pipSet.contains(.MEMORY_CONFIGURATION_PROTOCOL) {
                    NavigationLink(destination: CdCdiView(displayNode: displayNode, lib: network)) {
                        MoreButtonView(label: "Configure", symbol: "square.and.pencil")
                    }
                }
                
                NavigationLink(destination: IdentView(network: network, displayNode: displayNode)) {
                    MoreButtonView(label: "Ident", symbol: "rays")
                }
                
                if displayNode.pipSet.contains(.EVENT_EXCHANGE_PROTOCOL) {
                    NavigationLink(destination: EventView(displayNode: displayNode)) {
                        MoreButtonView(label: "Events", symbol: "cpu")
                    }
                }
                
                // we don't condition this on FirmwareUpdate in PIP because OpenMRN apps dont set that bit
                NavigationLink(destination: UpdateFirmwareView(node: displayNode, model: UpdateFirmwareModel(mservice: network.mservice, dservice: network.dservice, node: displayNode))) {
                    MoreButtonView(label: "Update Firmware", symbol: "arrow.down.doc")
                }

                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    MoreButtonView(label: "More Info", symbol: "gear.badge.questionmark")
                }
                                    
            }.frame(minHeight: 75)
                
#if os(macOS)
            Button("Refresh") {
                refresh()
            }.padding(.bottom, 15)
                .padding(.top, -15)
#endif
                
        } .navigationTitle("\(displayNode.name) Summary")
    }

    /// iOS and macOS specific handling of the sub-view navigation buttons
    struct MoreButtonView: View {
        let label: String
        let symbol: String
        
        var body: some View {
            VStack {
#if os(iOS)
                Image(systemName: symbol)
                Text(label)
                    .font(.footnote)
#else   // macOS
                Text(label)
#endif
            }
        }
    }
    
    func refresh() {
        network.refreshNode(node: displayNode)
        
        // reloadRoster() here would happen too soon, network update hasn't happened yet
        // so schedule for a short time from now
        let deadlineTime = DispatchTime.now() + .milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            network.throttleModel0.reloadRoster()
        }
    }
    
}

/// XCode preview for the NodeSummaryView
struct NodeSummaryView_Previews: PreviewProvider {
    static let displayNode  = Node(NodeID(258),
                                   snip: SNIP(
                                            "Manufacturer Name",
                                            "Model Info",
                                            "Hardware Info",
                                            "And Software Info",
                                            "My Node Name",
                                            "And Description"))
    static var previews: some View {
        let olcblibrary = OpenlcbNetwork(localNodeID: NodeID(258))
        return NodeSummaryView(displayNode: displayNode, network: olcblibrary)
    }
}
