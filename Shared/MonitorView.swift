//
//  MonitorView.swift
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary

/// Displayes the contents from the PrintingProcessor, e.g. the OpenLCB traffic monitor
struct MonitorView: View {

    // single global observed object contains monitor info
    @ObservedObject var monitorModel:MonitorModel = MonitorModel.sharedInstance
    
    // TODO: Add some nice scrolling control so it stays at the bottom until user wants to stick on something
    var body: some View {
        ScrollView {
            VStack(spacing: 3) {
                ForEach(monitorModel.printingProcessorContentArray, id: \.id) { element in
                    HStack {
                        Text(element.line)
                            .font(.callout)
                        Spacer()  // force alignment of text to left
                    }
                    Divider()
                }
            }
            .navigationTitle("Monitor View")
        }
    }
}

/// XCode preview for the MonitorView
struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
