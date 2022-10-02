//
//  EventView.swift
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display the Events produced and consumed by a specific node as buttons that will produce the events.
struct EventView: View {
    
    @ObservedObject var displayNode : Node
    
    @EnvironmentObject var network : OpenlcbNetwork
    
#if os(macOS)
    let vertPadding : CGFloat = 0
    let innnerHorizontalPadding : CGFloat = 0
    let overallHorizontalPadding : CGFloat = 0.0
#else
    let vertPadding : CGFloat = -5
    let innnerHorizontalPadding : CGFloat = -15.0
    let overallHorizontalPadding : CGFloat = -10.0
#endif
    
    var body: some View {
        var produced = Array(displayNode.events.eventsProduced)
        produced.sort()
        var consumed = Array(displayNode.events.eventsConsumed)
        consumed.sort()
        return VStack {
            Divider() // Needed to align tops of columns
            HStack {
                List {
                    Text("Produces").font(.title).frame(alignment: .leading)
                    ForEach(produced, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                            .padding(.vertical, vertPadding)
                            .frame(height: STANDARD_BUTTON_HEIGHT)
                    }
#if os(iOS)
                    .listRowSeparator(.hidden)  // first supported in macOS 13
#endif
                }.padding(.horizontal, innnerHorizontalPadding)
                
                List {
                    Text("Consumes").font(.title).frame(alignment: .trailing)
                    ForEach(consumed, id:\.eventID) { (event) in
                        EventViewOneEvent(eventID: event).frame(alignment: .leading)
                            .padding(.vertical, vertPadding)
                            .frame(height: STANDARD_BUTTON_HEIGHT)
                    }
#if os(iOS)
                    .listRowSeparator(.hidden) // first supported in macOS 13
#endif
                }.padding(.horizontal, innnerHorizontalPadding)
                
            }.padding(.horizontal, overallHorizontalPadding)
        }.navigationTitle("\(displayNode.name) Events")
    }
    
    /// Present one event as an active button
    fileprivate struct EventViewOneEvent : View {
        @EnvironmentObject var openlcblib : OpenlcbNetwork
        
        let eventID : EventID
        
#if os(macOS)
        let horizPadding : CGFloat = 0
#else
        let horizPadding : CGFloat = -5
#endif
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let fontsize = Font.system(size: width / 12.5 ) // empirically derived
                
                StandardMomentaryButton(label: "\(eventID.description)", height: STANDARD_BUTTON_HEIGHT, font: fontsize) {
                    openlcblib.produceEvent(eventID: eventID)
                } .padding(.horizontal, horizPadding)
            }
        }
    }
}

struct EventView_Previews: PreviewProvider {
    static let displayNode = Node(NodeID(12))
    static var previews: some View {
        displayNode.events.eventsConsumed.insert(EventID("1.2.3.4.5.6.7.8"))
        
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.8"))
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.9"))
        displayNode.events.eventsProduced.insert(EventID("1.2.3.4.5.6.7.7"))
        
        return EventView(displayNode : displayNode)
        //.previewInterfaceOrientation(.landscapeLeft)
    }
}
