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
    let displayNode : Node
    let lib : OpenlcbLibrary
    
    var body: some View {

        //#if os(macOS)
        // TODO: sort out iOS vs macOS here (and also matching bracket below)
        //NavigationView { // TODO: needed on macOS native to activate buttons; creates three column view; but re-pressing buttons still fails - need to navigate back somehow? But causes problems on Mac Catalyst
        //#endif
        VStack( /* alignment: .leading */) {
            // TODO: Making this a list (instead of a VStack) to allow pull-to-refresh messes up navigation: Buttons don't go where they're supposed to, and can only be clicked once. The back link from those shows "Back" unless you un-comment the navigationTitle items below. But having them uncommented when using a VStack results in wrong titles on pages when navigating back.
            Text(displayNode.name).font(.title)
            Text(displayNode.snip.userProvidedDescription)
            Text(displayNode.id.description) // nodeID

            // TODO: Make these conditional on whether the capability is present to suppress them on e.g. JMRI
            HStack{
                NavigationLink(destination: EventView(displayNode: displayNode)) {
                    VStack {
                        Image(systemName:"cpu")
                        //.resizable().frame(width:50, height:50)
                        Text("Events")
                            .font(.footnote)
                    }
                } //.navigationTitle("Events")
                                
                NavigationLink(destination: CdCdiView(displayNode: displayNode, lib: lib)) {
                    VStack {
                        Image(systemName:"square.and.pencil")
                        //.resizable().frame(width:50, height:50)
                        Text("Configure")
                            .font(.footnote)
                    }
                } //.navigationTitle("Configure")
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    VStack {
                        Image(systemName:"gear.badge.questionmark")
                        //.resizable().frame(width:50, height:50)
                        Text("More Info")
                            .font(.footnote)
                    }
                } //.navigationTitle("More Info")
            }.frame(minHeight: 75)
            
            Text(displayNode.snip.modelName)
            Text(displayNode.snip.manufacturerName)
            Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
        } .navigationTitle("\(displayNode.name) Summary")
         
    //#if os(macOS)
    //}.navigationTitle("\(displayNode.name) Summary") // end of macOS-only Navigation view
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
        let olcblibrary = OpenlcbLibrary(defaultNodeID: NodeID(258))
        return NodeSummaryView(displayNode: displayNode, lib: olcblibrary)
    }
}
