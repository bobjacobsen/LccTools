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

//#if os(macOS)
//#warning("macOS navigation in NodeSummaryView has not been sorted out yet")
// TODO: sort out iOS vs macOS here (and also matching bracket below)
// NavigationView { // needed on macOS native to activate buttons; creates three column view; but re-pressing buttons still fails - need to navigate back somehow? But causes problems on Mac Catalyst
//#endif
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
                if displayNode.pipSet.contains(.EVENT_EXCHANGE_PROTOCOL) {
                    NavigationLink(destination: EventView(displayNode: displayNode)) {
                        VStack {
                            Image(systemName:"cpu")
                            //.resizable().frame(width:50, height:50)
                            Text("Events")
                                .font(.footnote)
                        }
                    } //.navigationTitle("Events")
                }
                
                if displayNode.pipSet.contains(.CONFIGURATION_DESCRIPTION_INFORMATION)
                        && displayNode.pipSet.contains(.MEMORY_CONFIGURATION_PROTOCOL)  {
                    NavigationLink(destination: CdCdiView(displayNode: displayNode, lib: network)) {
                        VStack {
                            Image(systemName:"square.and.pencil")
                            //.resizable().frame(width:50, height:50)
                            Text("Configure")
                                .font(.footnote)
                        }
                    } //.navigationTitle("Configure")
                }
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    VStack {
                        Image(systemName:"gear.badge.questionmark")
                        //.resizable().frame(width:50, height:50)
                        Text("More Info")
                            .font(.footnote)
                    }
                } //.navigationTitle("More Info")
                
            }.frame(minHeight: 75)
            
        } .navigationTitle("\(displayNode.name) Summary")
         
//#if os(macOS)
//x`}.navigationTitle("\(displayNode.name) Summary") // end of macOS-only Navigation view
//#endif
            
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
