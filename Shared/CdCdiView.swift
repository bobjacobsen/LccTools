//
//  CdCdiView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct CdCdiView: View {
    
    // start with Segment elements present
    @ObservedObject var model : CdiModel

    var displayNode: Node
    let lib : OpenlcbLibrary

    init(displayNode: Node, lib: OpenlcbLibrary){
        self.displayNode = displayNode
        self.lib = lib
        
        // does the node already have CDI that's currently loaded
        if displayNode.cdi == nil || !displayNode.cdi!.loaded {
            // No, create it and load it - we're doing this as early as possible
            displayNode.cdi = CdiModel(mservice: lib.mservice, nodeID: displayNode.id)
            displayNode.cdi!.readModel(nodeID: displayNode.id)
        }
        model = displayNode.cdi!
    }
    
    // TODO: contains a lot of print statements; remove or change to logging
    
    var body: some View {
        VStack {
            if (model.loading) {
                Text("\(model.nextReadAddress) bytes read")
                ProgressView() // TODO: needs to read memory space size and show fraction done
            }
            List(model.tree, children: \.children) { row in  // "children" makes the nested list
                containedView(item: row, model: model)
            }.padding(10).navigationTitle("Node Configuration")
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
            Button("R") {    // TODO: needs to be hooked to model to do Refresh
                action()
                print("Refresh pressed for \(address)")
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
            Button("W") {    // TODO: needs to be hooked to model to do Write
                action()
                print("Write pressed for \(address)")
            }
            .font(.body)
            .foregroundColor(.white)
        }
    }
}

// view for an eventID value entry
struct CdiEventView : View {
    @State var eventValue : String = "00.00.00.00.00.00.00.00" // TODO:  initial value vs read?
    var item : CdiXmlMemo
    let model : CdiModel
    init(item : CdiXmlMemo, model : CdiModel) {
        self.item = item
        self.model = model
        print ("Event init starts")
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", text: $eventValue) // TODO: needs custom formatter
                    .onAppear {
                        print ("EventID appears with \(eventValue) current: \(self.item.currentIntValue)")
                        eventValue = item.currentStringValue
                    }
                    .onSubmit {
                        print ("EventID submits with \(eventValue) prior current: \(self.item.currentIntValue)")
                        item.currentStringValue = eventValue  // TODO: capture this to do a write
                    }
                Spacer()
                RButtonView(address: self.item.startAddress, model: model){
                    self.eventValue = self.eventValue+" +"
                    print ("Can update value to \(self.eventValue)")
                }
                WButtonView(address: self.item.startAddress, model: model){
                    print ("Can read value of \(self.eventValue)")
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
        print ("Int init starts")
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", value: $intValue,  formatter: formatter)
                    .onAppear {
                        print ("Int appears with \(intValue) current: \(self.item.currentIntValue)")
                        intValue = item.currentIntValue
                    }
                    .onSubmit {
                        print ("Int submits with \(intValue) prior current: \(self.item.currentIntValue)")
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
    var startUpIgnoreReceive = true // true while onReceive should be ignored untiul first onAppear
    
    init(item : CdiXmlMemo, model: CdiModel) {
        self.item = item
        self.model = model
        print ("Int map init starts \(self.item.defaultValue) \(self.item.currentIntValue)")
        intValue = item.currentIntValue
        stringValue = propertyToValue(property: intValue)
        print (" Int map init done with stringValue is \(stringValue)")
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
                        print ("IntMap appears with \(intValue) \(stringValue) current: \(self.item.currentIntValue)")
                        print ("   int \(item.currentIntValue) maps to \(propertyToValue(property: item.currentIntValue))")
                        intValue = item.currentIntValue
                        stringValue = propertyToValue(property: intValue)
                    }
                    .onReceive([self.stringValue].publisher.first()) { (value) in  // store back to model
                        print ("onReceive with \(value)")
                        print ("    start with \(intValue) \(stringValue) current: \(self.item.currentIntValue)")
                        print ("    string maps to \(valueToProperty(value: stringValue))")
                        if (stringValue == "<initial internal content>") {
                            print ("  and returning initially")
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
        print ("String init starts")
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
