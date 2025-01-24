//
//  CdCdiView.swift
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import os

// TODO: Maybe add a refresh that reloads the CDI, to handle partial reads on drop?

/// DIsplay the CDI information and allow user editing.
///
/// Gets its information from OpenlcbLibrary/CdiModel
struct CdCdiView: View {

    @ObservedObject var model: CdiModel
    
    var displayNode: Node
    let network: OpenlcbNetwork
    
    private static let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "CdCdiView")
    
    /// Loads the CDI from the LCC if it's not already present in a contained CdiModel
    init(displayNode: Node, lib: OpenlcbNetwork) {
        self.displayNode = displayNode
        self.network = lib
        
        // does the node already have CDI that's currently loaded
        if displayNode.cdi == nil {
            // No, create it and load it - we're doing this as early as possible
            displayNode.cdi = CdiModel(mservice: lib.mservice, nodeID: displayNode.id)
            displayNode.cdi!.readLengthAndModel(nodeID: displayNode.id)
        }
        model = displayNode.cdi!
    }
    
    var body: some View {
        VStack {
            if model.loading {
                Text("\(model.nextReadAddress) bytes read") // dynamically updates
                if model.readLength > 0 {
                    // if we could retrieve the CDI length
                    let progress = Double(model.nextReadAddress)/(Double(model.readLength)+1.0)
                    ProgressView(value: min(1.0, progress)) // sometimes overruns by a few in last read block, min(..) to avoid error message
                } else {
                    // if couldn't retrieve length
                    ProgressView()  // just the turning circle
                }
            }
            List(model.tree, children: \.children) { row in  // "children" makes the nested list
                containedView(item: row, model: model)
            }.padding()
                .navigationTitle("\(displayNode.name) Configuration")
        } // end VStack
    }
    
    /// Decode each item (CdiXmlMemo node) and provide appropriate view
    func containedView(item: CdiXmlMemo, model: CdiModel) -> AnyView {
        switch item.type {
        case .TOPLEVEL:
            return AnyView(Text(item.name))
            // return AnyView(Text("Top Level").font(.title))
        case .SEGMENT:
            if !item.description.isEmpty {
                return AnyView(VStack(alignment: .leading) {
                    Text(item.name).font(.title)
                    Text(item.description).font(.footnote)
                })
            } else {
                return AnyView(Text(item.name).font(.title))
            }
        case .GROUP:
            if !item.description.isEmpty {
                return AnyView(VStack(alignment: .leading) {
                    Text(item.name).font(.title2)
                    Text(item.description).font(.footnote)
                })
            } else {
                return AnyView(Text(item.name).font(.title2))
            }
        case .INPUT_EVENTID:
            if item.properties.isEmpty { // no map
                return AnyView(CdiEventView(item: item, model: model))
            } else {
                CdCdiView.logger.error("CdiEventMapView requested, but not yet implemented")
                return AnyView(CdiEventView(item: item, model: model)) // TODO: add CdiEventMapView here
            }
        case .INPUT_INT:
            if item.properties.isEmpty { // no map
                return AnyView(CdiIntView(item: item, model: model))
            } else {
                return AnyView(CdiIntMapView(item: item, model: model))
            }
        case .INPUT_STRING:
            return AnyView(CdiStringView(item: item, model: model))
        case .UNKNOWN_SIZED:
            // this is a future expansion item - we don't show it
            return AnyView(VStack(alignment: .leading) {
                Text(item.name)
                Text(item.description).font(.footnote)
            })
        default:
            // this includes a lot of elements: .UNKNOWN_UNSIZED, identification, etc
            return AnyView(VStack(alignment: .leading) {
                Text(item.name)
                Text(item.description).font(.footnote)
            })
        }
    }
    
    private struct DescriptionView: View {
        var item: CdiXmlMemo
        
        var body: some View {
            if !item.description.isEmpty {
                HStack {
                    Text(item.description)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                    BeyondTheButtons()
                }
            }
        }
    }

    /// View for a CID eventID value entry
    /// 
    ///  This crashes if you open a section that
    ///  reads for initialization
    struct CdiEventView: View {
        @State var eventValue: String = "00.00.00.00.00.00.00.00"
        var item: CdiXmlMemo
        let model: CdiModel
        init(item: CdiXmlMemo, model: CdiModel) {
            self.item = item
            self.model = model
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(item.name) ") // display name next to value
                        .fixedSize(horizontal: false, vertical: true)
                    
                    TextField("Enter \(item.name)", text: $eventValue)
                        .onAppear {
                            eventValue = item.currentStringValue
                        }
                        .onSubmit {
                            // process into a proper event format  // TODO: needs custom formatter? or just hex keyboard, adding dots automatically?
                            eventValue = EventID(eventValue).description
                            item.currentStringValue = eventValue
                        }
                        .textFieldStyle(.roundedBorder)
                    IosSpacer()
                    RButtonView(address: self.item.startAddress, model: model) {
                        read()
                    }
                    WButtonView(address: self.item.startAddress, model: model) {
                        model.writeEvent(value: EventID(eventValue).eventID, at: self.item.startAddress,
                                         space: UInt8(self.item.space), length: UInt8(self.item.length))
                    }
                    BeyondTheButtons()
                }.buttonStyle(BorderlessButtonStyle())

                DescriptionView(item: item)

            }
            .onAppear { read() }
        }

        func read() {
            model.readEvent(from: self.item.startAddress, space: UInt8(self.item.space), length: 8) { (readValue: UInt64) in
                self.eventValue = EventID(UInt64(readValue)).description
            }
        }
    }

    /// View for an Int CDI value entry
    struct CdiIntView: View {
        @State var intValue: Int = -1 // -1 so we can see what it does here
        var formatter = NumberFormatter()
        var item: CdiXmlMemo
        let model: CdiModel
        init(item: CdiXmlMemo, model: CdiModel) {
            self.item = item
            self.model = model
            formatter.minimum = item.minValue as NSNumber
            formatter.maximum = item.maxValue as NSNumber
            formatter.maximumFractionDigits = 0
            // print ("Init CdiIntView \(item.name) with min=\(String(describing: formatter.minimum) ) max=\(String(describing: formatter.maximum))")
            // print ("                 minSet=\(String(describing: item.minSet) ) maxSet=\(String(describing: item.maxSet))")
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(item.name) ") // display name next to value
                        .fixedSize(horizontal: false, vertical: true)
                    
                    TextField("Enter \(item.name)", value: $intValue, formatter: formatter)
                        .onAppear {
                            intValue = item.currentIntValue
                        }
                        .onSubmit {
                            item.currentIntValue = intValue
                        }
                        .textFieldStyle(.roundedBorder)
                    IosSpacer()
                    RButtonView(address: self.item.startAddress, model: model) {
                        read()
                    }
                    WButtonView(address: self.item.startAddress, model: model) {
                        model.writeInt(value: self.intValue, at: self.item.startAddress,
                                       space: UInt8(self.item.space), length: UInt8(self.item.length))
                    }
                    BeyondTheButtons()
                }.buttonStyle(BorderlessButtonStyle())

                DescriptionView(item: item)

                if item.maxSet || item.minSet {
                    MinMaxView(item: item)
                }
            }
            .onAppear { read() }
        }
        
        func read() {
            model.readInt(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)) { (readValue: Int) in
                self.intValue = readValue
            }
        }
    }
    
    /// Show the minimum and/or maximum values for an Int variable
    private struct MinMaxView: View {
        let text: String
        init(item: CdiXmlMemo) {
            var viewText = ""
            if item.minSet {
                viewText += "Min = \(item.minValue) "
            }
            if item.maxSet {
                viewText += "Max = \(item.maxValue) "
            }
            text = viewText
        }
        var body: some View {
            Text(text).font(.footnote)
        }
    }
    
    /// View for a CDI int value map
    struct CdiIntMapView: View {
        @State var intValue: Int = -1 // -1 so we can see what it does here
        @State var stringValue: String = "<initial internal content>" // so we can see what it does here
        
        var item: CdiXmlMemo
        let model: CdiModel
        var startUpIgnoreReceive = true // true while onReceive should be ignored until first onAppear
        
        init(item: CdiXmlMemo, model: CdiModel) {
            self.item = item
            self.model = model
            intValue = item.currentIntValue
            stringValue = propertyToValue(property: intValue)
        }
        
        func valueToProperty(value: String ) -> Int {
            // find index of matching value
            let index = self.item.values.firstIndex(of: value) ?? 0  // really supposed to match
            return Int(self.item.properties[index]) ?? 0 // 0 if process fails
        }
        func propertyToValue(property: Int ) -> String {
            // find index of matching property
            let index = self.item.properties.firstIndex(of: String(property)) ?? 0  // really supposed to match
            return self.item.values[index]
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        Picker("\(item.name)", selection: $stringValue) {
                            ForEach(item.values, id: \.self) { valueName in
                                Text(valueName)
                            }
                        } // default is no picker style, see https://developer.apple.com/documentation/swiftui/pickerstyle
                        .pickerStyle(MenuPickerStyle())
                        .onAppear { // initialize from model value
                            intValue = item.currentIntValue
                            stringValue = propertyToValue(property: intValue)
                        }
                        .onReceive([self.stringValue].publisher.first()) { (_) in  // store back to model
                            if stringValue == "<initial internal content>" {
                                return
                            }
                            intValue = valueToProperty(value: stringValue)
                            item.currentIntValue = intValue
                        }
                    }
                    IosSpacer()
                    HStack {
                        RButtonView(address: self.item.startAddress, model: model) {
                            read()
                        }
                        WButtonView(address: self.item.startAddress, model: model) {
                            model.writeInt(value: self.intValue, at: self.item.startAddress,
                                           space: UInt8(self.item.space), length: UInt8(self.item.length))
                        }
                        BeyondTheButtons()
                    }.buttonStyle(BorderlessButtonStyle())
                }
                
                DescriptionView(item: item)
                
            }
            .onAppear { read() }
        }
        
        func read() {
            model.readInt(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)) { (readValue: Int) in
                self.intValue = readValue
                self.stringValue = propertyToValue(property: self.intValue)
            }
        }
    }
    
    /// Custom view for String data entry fields
    struct CdiStringView: View {
        var item: CdiXmlMemo
        let model: CdiModel
        
        init(item: CdiXmlMemo, model: CdiModel) {
            self.item = item
            self.model = model
        }
        
        @State private var entryText: String = ""
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(item.name) ") // display name next to value
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("Enter \(item.name)", text: $entryText)
                        .textFieldStyle(.roundedBorder)
                    IosSpacer()
                    RButtonView(address: self.item.startAddress, model: model) {
                        read()
                    }
                    WButtonView(address: self.item.startAddress, model: model) {
                        model.writeString(value: self.entryText, at: self.item.startAddress,
                                          space: UInt8(self.item.space), length: UInt8(self.item.length))
                    }
                    BeyondTheButtons()
                }.buttonStyle(BorderlessButtonStyle())

                DescriptionView(item: item)
                
            }
            .onAppear { read() }
        }
        
        func read() {
            model.readString(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)) { (readValue: String) in
                self.entryText = readValue
            }
        }
    }
}

/// On macOS, provide some extra space past the buttons
private struct BeyondTheButtons: View {
    var body: some View {
#if os(macOS)
        Text(" ")  // space off side to solve overlap with window edge on macOS
            .frame(minWidth: 30)
#else
        EmptyView() // iOS doesn't need extra space at end of line
#endif
    }
}

/// On iOS, provide a spacer to push buttons to right
private struct IosSpacer: View {
    var body: some View {
#if os(iOS)
        Spacer()
#else
        EmptyView()
#endif
    }
}

/// View for a CD/CDI read/refresh button
private struct RButtonView: View {
    let address: Int
    let model: CdiModel
    let action: () -> Void
    
    var body: some View {
        CommonButtonView(text: "R", address: address, model: model, action: action)
    }
}

/// View for a CD/CDI write button
private struct WButtonView: View {
    let address: Int
    let model: CdiModel
    let action: () -> Void
    
    var body: some View {
        CommonButtonView(text: "W", address: address, model: model, action: action)
    }
}

/// Common section of R and W buttons
/// TODO: Should use standard button implementation
private struct CommonButtonView: View {
    let text: String
    let address: Int
    let model: CdiModel
    let action: () -> Void
    
    var body: some View {
        Button(
            action: action,
            label: {
                ZStack { // formatted button for recognition
                    RoundedRectangle(cornerRadius: 10.0)
                        .frame(width: 30, height: 30, alignment: .center)
                        .foregroundColor(.green)
                    Text(text)
                        .frame(width: 30, height: 30, alignment: .center)
                        .font(.body)
                        .foregroundColor(.white)
                }
            }
        ).buttonStyle(.borderless)  // for macOS
    }
}

/// XCode preview for the CdCdiView
struct CdCdiView_Previews: PreviewProvider {
    static var previews: some View {
        let network = OpenlcbNetwork(localNodeID: NodeID(123))
        let displayNode = Node(NodeID(321))
        let cdiModel = CdiModel(mservice: network.mservice, nodeID: NodeID(321))
        cdiModel.setTree(newTree: CdiSampleDataAccess.sampleCdiXmlData())
        //  load test CDI string to displayNode.cdi
        displayNode.cdi = cdiModel
        
        return CdCdiView(displayNode: displayNode, lib: network)
    }
}
