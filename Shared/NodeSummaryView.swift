//
//  NodeSummaryView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display of the details of a single node.
/// Invoked from e.g. NodeListNavigationView
struct NodeSummaryView: View {
    @ObservedObject var displayNode : Node
    let network : OpenlcbNetwork
    
    var body: some View {

        VStack( /* alignment: .leading */) {
            List {
                Text(displayNode.name).font(.title)
                Text(displayNode.snip.userProvidedDescription)
                Text(displayNode.id.description) // nodeID
                Text(displayNode.snip.modelName)
                Text(displayNode.snip.manufacturerName)
                Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
            }.refreshable {
                network.refreshNode(node: displayNode)
                
                // reloadRoster() here would happen too soon, network update hasn't happened yet
                // so schedule for a second from now
                let deadlineTime = DispatchTime.now() + .milliseconds(1000)
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    network.throttleModel0.reloadRoster()
                }
            }
            HStack{

                if displayNode.pipSet.contains(.CONFIGURATION_DESCRIPTION_INFORMATION)
                    && displayNode.pipSet.contains(.MEMORY_CONFIGURATION_PROTOCOL)  {
                    NavigationLink(destination: CdCdiView(displayNode: displayNode, lib: network)) {
                        VStack {
                            Image(systemName:"square.and.pencil")
                            Text("Configure")
                                .font(.footnote)
                        }
                    }
                }

#if os(iOS)

                if displayNode.pipSet.contains(.EVENT_EXCHANGE_PROTOCOL) {
                    NavigationLink(destination: EventView(displayNode: displayNode)) {
                        VStack {
                            Image(systemName:"cpu")
                            Text("Events")
                                .font(.footnote)
                        }
                    }
                }
   
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    VStack {
                        Image(systemName:"gear.badge.questionmark")
                        Text("More Info")
                            .font(.footnote)
                    }
                }

#else // macOS seems to require there be only two buttons/NavigationLinks

                NavigationLink(destination: MacOSCombinedView(displayNode: displayNode)) {
                    VStack {
                        Image(systemName:"gear.badge.questionmark")
                        Text("More Info")
                            .font(.footnote)
                    }
                }
#endif
                
            }.frame(minHeight: 75)
        } .navigationTitle("\(displayNode.name) Summary")
    }
}

struct MacOSCombinedView : View {
    @ObservedObject var displayNode : Node

    var body : some View {
        VStack {
            PipView(displayNode: displayNode)
            StandardHDivider()
            EventView(displayNode: displayNode)
        }
    }
}
struct FullNodeView_Previews: PreviewProvider {
    static let displayNode  = Node(NodeID(258),
                                   snip: SNIP(
                                            "Manufacturer Name",
                                            "Model Info",
                                            "Hardware Info",
                                            "And Software Info",
                                            "My Node Name",
                                            "And Description"))
    static var previews: some View {
        let olcblibrary = OpenlcbNetwork(defaultNodeID: NodeID(258))
        return NodeSummaryView(displayNode: displayNode, network: olcblibrary)
    }
}
