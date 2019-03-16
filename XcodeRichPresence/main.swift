//
//  main.swift
//  XcodeRichPresence
//
//  Created by Julian Schiavo on 15/3/2019.
//  Copyright © 2019 Julian Schiavo. All rights reserved.
//

import Foundation
import SwordRPC

class XcodeRichPresence {
    struct XcodeInfo {
        var fileName: String
        var projectName: String
    }
    
    var lastChanged = Date()
    var lastInfo = XcodeInfo(fileName: "", projectName: "")
    
    var timer: Timer!
    
    // You don't need to change this unless you want a different IMAGE
    let rpc = SwordRPC(appId: "556100850800656414")
    
    func getCurrentXcodeInfo() -> XcodeInfo? {
        let script = """
            tell application "Xcode"
            set CurrentActiveDocument to document 1 whose name ends with (word -1 of (get name of window 1))
            set DocumentName to name of CurrentActiveDocument
            set ActiveWorkspaceName to name of active workspace document
            return DocumentName & "|" & ActiveWorkspaceName
            end tell
        """
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else { fatalError("Failed to setup AppleScript.") }
        let output = scriptObject.executeAndReturnError(&error)
        
        guard error == nil,
            let fileName = output.stringValue?.split(separator: "|")[0],
            let projectName = output.stringValue?.split(separator: "|")[1] else {
                return nil
        }
        
        let info = XcodeInfo(fileName: String(fileName), projectName: String(projectName))
        if info.fileName != lastInfo.fileName || info.projectName != lastInfo.projectName {
            lastChanged = Date()
            lastInfo = info
        }
        
        return info
    }
    
    @objc func setRPC() {
        guard let info = getCurrentXcodeInfo() else { return }
        print("Xcode Info", info.fileName, info.projectName)
        
        var presence = RichPresence()
        presence.details = "Editing \(info.fileName)"
        presence.state = "In \(info.projectName)"
        presence.timestamps.start = lastChanged
        presence.assets.largeImage = "xcode"
        presence.assets.largeText = "Xcode"
//        presence.assets.smallImage = "xcode"
//        presence.assets.smallText = ""

        rpc.setPresence(presence)
    }
    
    func start() {
        print("Hello, World!")
        
        rpc.onConnect { rpc in
            print("Connecting")
            self.setRPC()
        }
        
        rpc.onDisconnect { rpc, code, msg in
            print("Error: Disconnected (\(String(describing: msg)))")
        }
        
        rpc.onError { rpc, code, msg in
            print("Error: \(code)\(msg)")
        }
        
        rpc.connect()
        setRPC()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.setRPC), userInfo: nil, repeats: true)
    }
}

let manager = XcodeRichPresence()
manager.start()

// Make the script run indefinitely
RunLoop.main.run()
