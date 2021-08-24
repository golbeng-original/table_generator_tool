//
//  ProgressViewController.swift
//  table_generator_tool2
//
//  Created by bjunjo on 2021/08/20.
//

import Foundation
import Cocoa

class ProgressViewContorller : NSViewController
{
    @IBOutlet var progress_consoleProgress: NSProgressIndicator!
    @IBOutlet var label_consoleProgress: NSTextField!
    
    @IBOutlet var textView_scroll: NSScrollView!
    @IBOutlet var textView_output: NSTextView!
    
    @IBOutlet var button_ok: NSButton!
    
    private var _coreCommand:CoreCommand!
    private var _commandName:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button_ok.isEnabled = false
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
    }
    
    public func registerCommandName(commandName:String)
    {
        _commandName = commandName
    }
    
    public func progressUpdate(progress:Double, progressText:String)
    {
        DispatchQueue.main.sync
        {
            self.progress_consoleProgress.doubleValue = progress
            
            self.label_consoleProgress.stringValue = progressText
        
            if let documentview = self.textView_scroll.documentView {
                documentview.scroll(NSPoint(x: 0, y: documentview.bounds.size.height))
            }
        }
    }
    
    public func updateOutput(output:String)
    {
        DispatchQueue.main.sync
        {
            self.textView_output.string += output + "\n"
        }
    }
    
    public func progressComplete()
    {
        // 완료 되었다는 효과를 위해(너무 빨라서 0.5초 딜레이 주었음.)
        Thread.sleep(forTimeInterval: 0.5)
        
        DispatchQueue.main.async {
            self.button_ok.isEnabled = true
        }
    }

    
    @IBAction func doClickOk(_ sender: Any) {
        self.view.window?.close()
    
        if _commandName != nil
        {
            NotificationCenter.default.post(name: .init("didReceiveCommandProgressNotification"), object: _commandName!)
        }
        

    }
}

extension ProgressViewContorller
{
    public func registerCoreCommandAutoComplete(coreCommand:CoreCommand, runable: (_ coreCommand:CoreCommand)throws->Void) throws
    {
        coreCommand.registerTerminateHandler { ret in
            self.progressComplete()
        }
    
        try self.registerCoreCommandManualComplete(coreCommand: coreCommand, runable: runable)
    }
    
    public func registerCoreCommandManualComplete(coreCommand:CoreCommand, runable: (_ coreCommand:CoreCommand)throws->Void) throws
    {
        _coreCommand = coreCommand
        
        _coreCommand.registerErrorMessageHandler
        {
            self.updateOutput(output: $0)
        }
        
        _coreCommand.registerOutputMessageHandler
        {
            if let stateMap = $0 as? [String: Any] {
            
                guard let state = stateMap["state"] as? String else {
                    return
                }
                
                if state == "progress"
                {
                    
                    guard let progress = stateMap["progress"] as? Double else {
                        return
                    }
                    
                    guard let progress_text = stateMap["progress_text"] as? String else {
                        return
                    }
                    
                    self.progressUpdate(progress: progress, progressText: progress_text)
                    self.updateOutput(output: progress_text)
                    
                    return
                }
                else if state == "error"
                {
                    
                    guard let error = stateMap["error"] as? String else {
                        return
                    }
                    
                    self.updateOutput(output: error)
                }
            }
            else if let list = $0 as? [String] {
                self.updateOutput(output: list.joined(separator: "\n"))
            }
            else if let str = $0 as? String {
                self.updateOutput(output: str)
            }
        }
        
        try runable(_coreCommand)
    }
    
}
