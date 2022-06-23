//
//  StackOverflowExample.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/21/22.
// Used for StackOverflow question https://stackoverflow.com/questions/72698861/swiftui-navigation-works-on-ios-but-fails-on-macos/72700472#72700472

import SwiftUI

struct TNode {  // simple data struct that just carries name and ID
    public let id = UUID()
    public let name : String
    init( _ name:String) {
        self.name = name
    }
}

// starting view
struct StackOverflowView: View {
    init () {
        // provide some sample data
        nodes = [TNode("node 1"), TNode("node 2")]
     }

    @State private var nodes : [TNode]

    var body: some View {
        NavigationView {
            List {
                ForEach(nodes, id:\.id) { (node) in
                    // where to go when selected
                    NavigationLink(destination:
                                    DetailView(displayNode: node)
                    ){ // display names for selection in the sidebar
                        VStack {
                            Text(node.name)
                        }
                    }
                }
            }
        }
    }
}

struct DetailView: View {
    let displayNode : TNode
    
    var body: some View {
        NavigationView {
        VStack(alignment: .leading) {
            
            Text(displayNode.name)
            
            HStack{
                // this is what doesn't work on macOS
                NavigationLink(destination: FinalView1()) {
                    Image(systemName:"figure.stand.line.dotted.figure.stand")
                }
                 
                NavigationLink(destination: FinalView2()) {
                        Image(systemName:"square.and.pencil")
                }
            }
        }
        }
    }
}

struct FinalView1 : View {
    var body : some View {
        Text("Got to final view 1 OK")
    }
}

struct FinalView2 : View {
    var body : some View {
        Text("Got to final view 2 OK")
    }
}


