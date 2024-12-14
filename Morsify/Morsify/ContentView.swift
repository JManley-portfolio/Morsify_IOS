//
//  ContentView.swift
//  Morsify
//
//  Created by Joel Manley on 12/6/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var input: String = ""
    @State private var convertedInput: String = ""
    
    let morseDictionary: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.",
        "G": "--.", "H": "....", "I": "--", "J": ".---", "K": "-.-", "L": ".-..",
        "M": "--", "N": "-.", "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.",
        "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..", " ": "_"
    ]
    
    var body: some View {
        VStack {
            Text("Morsify")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 50)
            
            TextField("Enter word or phrase to morsify:", text: $input)// binding
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .background(Color.white)
                .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                .padding(.horizontal, 30)
                .padding(.top, 30)
            
            // button container
            HStack {
                Button(action: {
                    // convert method
                    convertedInput = convertToMorse(input: input, dictionary: morseDictionary)
                    checkCameraPermission()
                    flashMorse(message: convertedInput, toggleFlashOn: toggleFlashOn, toggleFlashOff: toggleFlashOff)
                }){
                    Text("Morsify")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
                
                Button(action: {
                    // clear text field
                    convertedInput = ""
                    input = ""
                }) {
                    Text("Clear")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
            }
            .padding(.top, 30)
            
            if !convertedInput.isEmpty {
                Text("Entered: \(convertedInput)")
                    .padding()
                    .foregroundColor(.white)
                    .font(.title2)
            }
            Spacer() // fills the rest of the screen
        }
        .padding()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
}

func convertToMorse(input: String, dictionary: [Character: String])-> String {
    let uppercaseString: String = input.uppercased()
    let morse = uppercaseString.compactMap { Character in
        return dictionary[Character]
    }.joined(separator: " ")
    
    return morse.appending("~")
}

func flashMorse(message: String, toggleFlashOn: @escaping () -> Void,
                                toggleFlashOff: @escaping () -> Void) { //allows toggleFlash to exist outside current scope
    //take all characters in string, save to array of strings containing a single character
    let symbols = message.map{String($0)}
    var index = 0
    var flashOn = false
    
    let flashDurations: [String: TimeInterval] = [
        ".": 0.4, "-": 0.7, "_": 1.0
    ]
    
    func flashNext() {
        let symbol = symbols[index]
        guard symbol != "~" else {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
                print("Connecting to camera incorrectly")
                return
            }
            if device.torchMode == AVCaptureDevice.TorchMode.on {
              toggleFlashOff()
            }
            return
        } //Base case to exit recursion at string end
        
        let flashDuration = flashDurations[symbol] ?? 0.0
    
        // turn on flash
        if (!flashOn) {
            print("Flash ON for \(symbol)")
            toggleFlashOn()
            flashOn =  true
            //print("On " + String(flashOn))
        }
        
        // turn flash off after pause
        DispatchQueue.main.asyncAfter(deadline: .now() + flashDuration) {
            if flashOn {
                print("Flash OFF for \(symbol)")
                toggleFlashOff()
                flashOn = false
                //print("on: " + String(flashOn))
            }
        }
        // take small pause between letters and flash next
        //let pauseDuration: TimeInterval = flashDuration + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            //print("pause between letters")
            index += 1
            //print("Flash state on: " + String(flashOn))
            flashNext()
        }
    } // END Flash next function
    flashNext() // begin recursvely flashing each character
} // END FlashMorse Function

func toggleFlashOn() {
    guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
        print("Connecting to camera incorrectly")
        return
    }
    guard device.hasTorch else {
        print("Device has no torch")
        return
    }
    do {
        try device.lockForConfiguration()
        if device.torchMode == AVCaptureDevice.TorchMode.off {
            device.torchMode = .on
            //print("Flash OFF")
        }
        device.unlockForConfiguration()
    } catch {
        print("Problem checking flash state")
    }
}

func toggleFlashOff() {
    guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
        print("Connecting to camera incorrectly")
        return
    }
    guard device.hasTorch else {
        print("Device has no torch")
        return
    }
    do {
        try device.lockForConfiguration()
        if device.torchMode == AVCaptureDevice.TorchMode.on {
            device.torchMode = .off
            //print("Flash OFF")
        }
        device.unlockForConfiguration()
    } catch {
        print("Problem checking flash state")
    }
}




func checkCameraPermission() {
    switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
    case .authorized:
        print("Authorized to use device camera")
        //toggleFlash()
        
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: AVMediaType.video){response in
            if response{
                print("Requested and granted camera permission")
          //      toggleFlash()
            } else{
                print("Camera Access requested and denied")
            }
        }
    case .denied, .restricted:
        print("Camera access denied or restricted")
    @unknown default:
        break
    }
}

#Preview {
    ContentView()
}
