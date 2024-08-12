//
//  MonitorView.swift
//
//  Created by Bob Jacobsen on 6/21/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display the contents from the PrintingProcessor, e.g. the OpenLCB traffic monitor
struct MonitorView: View {
    @StateObject var vm = ScrollToModel()

    // single global observed object contains monitor info
    @ObservedObject var monitorModel: MonitorModel = MonitorModel.sharedInstance
    
    // TODO: Add some nice scrolling control so it stays at the bottom until user wants to stick on something
    var body: some View {
        VStack {
            ScrollViewReader { sp in
               ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(monitorModel.printingProcessorContentArray, id: \.id) { element in
                            HStack {
                                Text(element.line)
                                    .font(.callout)
                                Spacer()  // force alignment of text to left
                            }
                            Divider()
                        }
                    }.onReceive(vm.$direction) { action in
                        guard !monitorModel.printingProcessorContentArray.isEmpty else { return }
                        withAnimation {
                            switch action {
                            case .top:
                                sp.scrollTo(monitorModel.printingProcessorContentArray.first!.id, anchor: .top)
                            case .end:
                                sp.scrollTo(monitorModel.printingProcessorContentArray.last!.id, anchor: .bottom)
                            default:
                                return
                            }
                        }
                    }
                    .navigationTitle("Monitor View")
                }
            }
            Spacer()
            HStack {
                StandardClickButton(label: "Start",
                                    height: SMALL_BUTTON_HEIGHT,
                                    font: SMALL_BUTTON_FONT) {
                    vm.direction = .top
                }
                StandardClickButton(label: "Clear",
                                    height: SMALL_BUTTON_HEIGHT,
                                    font: SMALL_BUTTON_FONT) {
                    monitorModel.clear()
                }
                StandardClickButton(label: "End",
                                    height: SMALL_BUTTON_HEIGHT,
                                    font: SMALL_BUTTON_FONT) {
                    vm.direction = .end
                }
            }
        }
    }

    // Internal helper class for moving to top/bottom.
    class ScrollToModel: ObservableObject {
        @Published var direction: MoveAction?
    }
    
    // Internal enum denoting direction to hold on screen.
    enum MoveAction {
        case end
        case top
    }
}

/// XCode preview for the MonitorView
struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
