//
//  StandardButtons.swift
//
//  Created by Bob Jacobsen on 8/19/22.
//

import SwiftUI

public let STANDARD_BUTTON_CORNER_RADIUS    = 15.0

public let STANDARD_BUTTON_HEIGHT           = 35.0
public let STANDARD_BUTTON_FONT             = Font.title  // 28pt by default; make this numeric to match HEIGHT?

public let SMALL_BUTTON_HEIGHT              = 25.0
public let SMALL_BUTTON_FONT                = Font.title2 // 22pt by default; make this numeric to match HEIGHT?

public let SMALLER_BUTTON_HEIGHT            = 20.0
public let SMALLER_BUTTON_FONT              = Font.body   // 17pt by default; make this numeric to match HEIGHT?

/// Button that toggles a state selected / not selected
struct StandardToggleButton: View {
    let label : String
    let height : CGFloat
    var font : Font
    @Binding var select : Bool
    let action : () -> Void
    
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: STANDARD_BUTTON_CORNER_RADIUS)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(
                            !isEnabled ? .gray : (
                            select ? .blue : .green)
                        )
                    
                    Text(label)
                        .font(font)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
        .buttonStyle(.borderless)  // for macOS
    }
}

/// Button that just goes down and up, calling an action
// TODO: This doesn't _show_ the click on macOS (you can't see that you clicked it) - see Event and Turnout displays. Does show the down/up on iOS OK.
struct StandardClickButton: View {
    let label : String
    var height : CGFloat = STANDARD_BUTTON_HEIGHT
    var font : Font = STANDARD_BUTTON_FONT
    let action : () -> Void
    
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: STANDARD_BUTTON_CORNER_RADIUS)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(isEnabled ? .green : .gray)
                    
                    Text(label)
                        .font(font)
                        .foregroundColor(.white)
                        .frame(height: height, alignment: .center)
                }
            } // label
        ) // Button
        .buttonStyle(.borderless)  // for macOS
    }
}

// See: https://serialcoder.dev/text-tutorials/swiftui/handle-press-and-release-events-in-swiftui/
/// Button that notifies on both down and up transition
struct StandardMomentaryButton: View {
    let label : String
    let height : CGFloat
    var font : Font
    let down : () -> Void
    let up : () -> Void
    
    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        
#if os(iOS)
        let retval = Button(action: {
        }, label: {
            Text(label)
                .font(font)
                .foregroundColor(.white)
        })
#else
        // on macOS, use a Text instead of a Button to get a completely clickable target
        let retval = Text(label)
            .font(font)
            .foregroundColor(.white)
#endif
        
        // apply modifiers and return
        return retval.frame(height: height, alignment: .center)
        .frame(maxWidth: .infinity)
        .background(isEnabled ? (!isPressed ? .green : .blue) : .gray)
        .cornerRadius(STANDARD_BUTTON_CORNER_RADIUS)
        .buttonStyle(.borderless)  // for macOS

        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    isPressed = true
                    down()
                })
                .onEnded({ _ in
                    isPressed = false
                    up()
                })
        )
        
        // end modifiers
    } // body
}


/// This centralizes horizontal dividers.
struct StandardHDivider : View {
    var body : some View {
        Divider()
            .frame(height: 1)
            .overlay(.gray)
    }
}

struct StandardButton_Previews: PreviewProvider {
    static var previews: some View {
        StandardButton_PreviewsView()
    }
}

// This is a separate struct to provide addedd to a @State variable in scope
struct StandardButton_PreviewsView : View {
    @State var forToggle = false
    @State private var momentaryIsPressed = false
    var body : some View {
        VStack {
            StandardClickButton(label: "Click",
                                height: STANDARD_BUTTON_HEIGHT,
                                font: STANDARD_BUTTON_FONT){
                // on pressed
            }
            
            StandardClickButton(label: "Click Disabled",
                                height: STANDARD_BUTTON_HEIGHT,
                                font: STANDARD_BUTTON_FONT){
                // on pressed
            }.disabled(true)
            
            StandardToggleButton(label: "Toggle",
                                 height: STANDARD_BUTTON_HEIGHT,
                                 font: STANDARD_BUTTON_FONT,
                                 select: $forToggle)
            {
                // on pressed
                forToggle = !forToggle
            }
            
            StandardToggleButton(label: "Toggle Disabled",
                                 height: STANDARD_BUTTON_HEIGHT,
                                 font: STANDARD_BUTTON_FONT,
                                 select: $forToggle)
            {
                // on pressed
                forToggle = !forToggle
            }.disabled(true)
            
            StandardClickButton(label: "Small Click",
                                height: SMALL_BUTTON_HEIGHT,
                                font: SMALL_BUTTON_FONT)
            {
                // on pressed
            }
            
            StandardToggleButton(label: "Small Toggle",
                                 height: SMALL_BUTTON_HEIGHT,
                                 font: SMALL_BUTTON_FONT,
                                 select: $forToggle)
            {
                // on pressed
                forToggle = !forToggle
            }
            
            StandardMomentaryButton(label: "Momentary",
                                    height: STANDARD_BUTTON_HEIGHT,
                                    font: SMALL_BUTTON_FONT,
                                    down: {momentaryIsPressed = true},
                                    up: {momentaryIsPressed = false}
            )
            
            StandardMomentaryButton(label: "Momentary Disabled",
                                    height: STANDARD_BUTTON_HEIGHT,
                                    font: SMALL_BUTTON_FONT,
                                    down: {momentaryIsPressed = true},
                                    up: {momentaryIsPressed = false}
            )
            .disabled(true)
 
            Text("Momentary Indicate")
                .foregroundColor(.white)
                .background(!momentaryIsPressed ?
                            Color(.systemGreen) :
                                Color(.black))

        }
    }
}
