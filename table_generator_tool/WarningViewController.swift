//
//  WarningViewController.swift
//  table_generator_tool
//
//  Created by bjunjo on 2021/08/20.
//

import Foundation
import Cocoa

class WarningViewController : NSViewController
{
    @IBOutlet var textView_output: NSTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public func setMessage(title:String, message:String)
    {
        self.view.window?.title = title
        
        textView_output.string = message
    }
    
    @IBAction func doClickOk(_ sender: Any) {
        self.view.window?.close()
    }
}
