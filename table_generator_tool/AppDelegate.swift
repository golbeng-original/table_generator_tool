//
//  AppDelegate.swift
//  table_generator_tool2
//
//  Created by bjunjo on 2021/08/19.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    
    @IBAction func doCoreSync(_ sender: Any)
    {
        let envInstallShell = Bundle.main.url(forResource: "env-install", withExtension: "command")
        
        if envInstallShell == nil {
            return
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Terminal", envInstallShell!.path]
        process.launch()
    }
    
    public static func showWarningAlert(message:String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }
    
    public static func showWarningWindow(_ controller:NSViewController, title:String, message:String)
    {
        let warningViewCtrl = controller.storyboard?.instantiateController(withIdentifier: "WarningViewController") as! WarningViewController
    
        controller.presentAsModalWindow(warningViewCtrl)
        
        warningViewCtrl.setMessage(title: title, message: message)
    }

    
    
}

