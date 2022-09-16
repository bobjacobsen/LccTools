//
//  CdCdiView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct CdCdiView: View {
    
    // TODO: is not properly handling a read already in progress, i.e. if you start one, move away, and return. That results in two reads running in parallel.
    // TODO: would be good to read values as they are shown instead of requiring hit "R"

    @ObservedObject var model : CdiModel

    var displayNode: Node
    let network : OpenlcbLibrary

    init(displayNode: Node, lib: OpenlcbLibrary){
        self.displayNode = displayNode
        self.network = lib
        
        // does the node already have CDI that's currently loaded
        if displayNode.cdi == nil || !displayNode.cdi!.loaded {
            // No, create it and load it - we're doing this as early as possible
            displayNode.cdi = CdiModel(mservice: lib.mservice, nodeID: displayNode.id)
            displayNode.cdi!.readModel(nodeID: displayNode.id)
        }
        model = displayNode.cdi!
    }
    
    var body: some View {
        VStack {
            if (model.loading) {
                Text("\(model.nextReadAddress) bytes read")
                ProgressView() // TODO: needs to read memory space size and show fraction done
            }
            List(model.tree, children: \.children) { row in  // "children" makes the nested list
                containedView(item: row, model: model)
            }.padding(10).navigationTitle("\(displayNode.name) Configuration")
        }
    }
}

// decode each item (CdiXmlMemo node) and display for all types of nodes
func containedView(item : CdiXmlMemo, model: CdiModel) -> AnyView {
    switch item.type {
    case .SEGMENT :
        if item.description != "" {
             return AnyView(VStack(alignment: .leading) {
                Text(item.name).font(.title)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title))
        }
    case .GROUP :
        if item.description != "" {
            return AnyView(VStack(alignment: .leading) {
                Text(item.name).font(.title2)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title2))
        }
    case .INPUT_EVENTID :
        if (item.properties.count == 0 ) { // no map
            return AnyView(CdiEventView(item: item, model: model))
        } else {
            return AnyView(CdiEventView(item: item, model: model)) // TODO: add CdiEventMapView here
        }
    case .INPUT_INT :
        if (item.properties.count == 0 ) { // no map
            return AnyView(CdiIntView(item: item, model: model))
        } else {
            return AnyView(CdiIntMapView(item: item, model: model))
        }
    case .INPUT_STRING :
        return AnyView(CdiStringView(item: item, model: model))
    default :
        if item.description != "" {
            return AnyView(VStack(alignment: .leading) {
                Text(item.name)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name))
        }
    }
}

// view for a read/refresh button
struct RButtonView : View {
    let address : Int
    let model : CdiModel
    let action : () -> ()
    
    var body : some View {
        ZStack { // formatted button for recognition
            RoundedRectangle(cornerRadius: 10.0)
                .frame(width: 40, height: 30, alignment: .center)
                .foregroundColor(.green)
            Button("R") {
                action()
            }
            .font(.body)
            .foregroundColor(.white)
        }
    }
}

// view for a store button
struct WButtonView : View {
    let address : Int
    let model : CdiModel
    let action : () -> ()

    var body : some View {
        ZStack { // formatted button for recognition
            RoundedRectangle(cornerRadius: 10.0)
                .frame(width: 40, height: 30, alignment: .center)
                .foregroundColor(.green)
            Button("W") {
                action()
            }
            .font(.body)
            .foregroundColor(.white)
        }
    }
}

// view for an eventID value entry
struct CdiEventView : View {
    @State var eventValue : String = "00.00.00.00.00.00.00.00"
    var item : CdiXmlMemo
    let model : CdiModel
    init(item : CdiXmlMemo, model : CdiModel) {
        self.item = item
        self.model = model
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", text: $eventValue) // TODO: needs custom formatter
                    .onAppear {
                        eventValue = item.currentStringValue
                    }
                    .onSubmit {
                        item.currentStringValue = eventValue
                    }
                Spacer()
                RButtonView(address: self.item.startAddress, model: model){
                    model.readInt(from: self.item.startAddress, space: UInt8(self.item.space), length: 8){
                        (readValue : Int) in
                        self.eventValue = EventID(UInt64(readValue)).description
                    }
                }
                WButtonView(address: self.item.startAddress, model: model){
                    model.writeInt(value: Int(EventID(eventValue).eventID), at: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length))
                }
            }.buttonStyle(BorderlessButtonStyle())
            if item.description != "" {
                Text(item.description).font(.footnote)
            }
        }
    }
}

// view for an int value entry
struct CdiIntView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    var formatter = NumberFormatter()
    var item : CdiXmlMemo
    let model : CdiModel
    init(item : CdiXmlMemo, model: CdiModel) {
        self.item = item
        self.model = model
        formatter.minimum = NSNumber(integerLiteral: item.minValue)
        formatter.maximum = NSNumber(integerLiteral: item.maxValue)
        formatter.maximumFractionDigits = 0
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", value: $intValue,  formatter: formatter)
                    .onAppear {
                        intValue = item.currentIntValue
                    }
                    .onSubmit {
                        item.currentIntValue = intValue
                    }
                Spacer()
                RButtonView(address: self.item.startAddress, model: model){
                    model.readInt(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)){
                        (readValue : Int) in
                        self.intValue = readValue
                    }
                }
                WButtonView(address: self.item.startAddress, model: model){
                    model.writeInt(value: self.intValue, at: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length))
                }
            }.buttonStyle(BorderlessButtonStyle())
            if item.description != "" {
                Text(item.description).font(.footnote)
            }
        }
    }
}

// view for an int value map
struct CdiIntMapView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    @State var stringValue : String = "<initial internal content>" // so we can see what it does here

    var item : CdiXmlMemo
    let model : CdiModel
    var startUpIgnoreReceive = true // true while onReceive should be ignored until first onAppear
    
    init(item : CdiXmlMemo, model: CdiModel) {
        self.item = item
        self.model = model
        intValue = item.currentIntValue
        stringValue = propertyToValue(property: intValue)
    }
    
    func valueToProperty(value : String ) -> Int {
        // find index of matching value
        let index = self.item.values.firstIndex(of: value) ?? 0  // really supposed to match
        return Int(self.item.properties[index]) ?? 0 // 0 if process fails
    }
    func propertyToValue(property : Int ) -> String {
        // find index of matching property
        let index = self.item.properties.firstIndex(of: String(property)) ?? 0  // really supposed to match
        return self.item.values[index]
   }

    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                HStack{
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
                    .onReceive([self.stringValue].publisher.first()) { (value) in  // store back to model
                        if (stringValue == "<initial internal content>") {
                            return
                        }
                        intValue = valueToProperty(value: stringValue)
                        item.currentIntValue = intValue
                    }
                }
                Spacer()
                HStack {
                    RButtonView(address: self.item.startAddress, model: model){
                        model.readInt(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)){
                            (readValue : Int) in
                            self.intValue = readValue
                            self.stringValue = propertyToValue(property: self.intValue)
                        }
                    }
                    WButtonView(address: self.item.startAddress, model: model){
                        model.writeInt(value: self.intValue, at: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length))
                    }
                }.buttonStyle(BorderlessButtonStyle())
            }
            Text(item.description).font(.footnote)
            
        }
    }
}

// custom for String data entry fields
struct CdiStringView : View {
    var item : CdiXmlMemo
    let model : CdiModel

    init(item : CdiXmlMemo, model: CdiModel) {
        self.item = item
        self.model = model
    }

    @State private var entryText : String = ""
    
    var body: some View {
        HStack {
            Text("\(item.name) ") // display name next to value
            Spacer()
            TextField("Enter \(item.name)", text : $entryText)

            //Spacer()
            RButtonView(address: self.item.startAddress, model: model){
                model.readString(from: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length)){
                    (readValue : String) in
                    self.entryText = readValue
                }
            }
            WButtonView(address: self.item.startAddress, model: model){
                model.writeString(value: self.entryText, at: self.item.startAddress, space: UInt8(self.item.space), length: UInt8(self.item.length))
            }
        }.buttonStyle(BorderlessButtonStyle())
    }
}

struct CdCdiView_Previews: PreviewProvider {
    static var previews: some View {
        CdCdiView(displayNode: Node(NodeID(123)), lib: OpenlcbLibrary(defaultNodeID: NodeID(123)))
    }
}
