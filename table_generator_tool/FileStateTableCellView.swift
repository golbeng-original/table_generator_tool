//
//  FileStateTableCellView.swift
//  table_generator_tool2
//
//  Created by bjunjo on 2021/08/20.
//

import Foundation
import Cocoa

class SchemaFileStateTableCellView : NSTableCellView
{
    @IBOutlet var checkBox_Selected: NSButton!
    @IBOutlet var label_fileName: NSTextField!

    private var _rowIndex = 0;
    private var _selectedAction:((_:Int, _:Bool)->Void)?
    
    public func registerIndex(index:Int) {
        _rowIndex = index
    }
    
    public func registerSelectedAction(action:(@escaping (_:Int,_:Bool)->Void)) {
        _selectedAction = action
    }

    @IBAction func updateSelectedState(_ sender: NSButton) {
        
        guard let selectedAction = _selectedAction else {
            return;
        }
        
        if sender.state == .on {
            selectedAction(_rowIndex, true);
        }
        else {
            selectedAction(_rowIndex, false);
        }
    }
}

class DataFileStateTableCellView : NSTableCellView
{
    @IBOutlet var checkBox_Selected: NSButton!
    @IBOutlet var label_fileName: NSTextField!
    
    private var _rowIndex = 0;
    private var _selectedAction:((_:Int, _:Bool)->Void)?
    
    public func registerIndex(index:Int) {
        _rowIndex = index
    }
    
    public func registerSelectedAction(action:(@escaping (_:Int,_:Bool)->Void)) {
        _selectedAction = action
    }

    @IBAction func updateSelectedState(_ sender: NSButton) {
        
        guard let selectedAction = _selectedAction else {
            return;
        }
        
        if sender.state == .on {
            selectedAction(_rowIndex, true);
        }
        else {
            selectedAction(_rowIndex, false);
        }
    }
}
