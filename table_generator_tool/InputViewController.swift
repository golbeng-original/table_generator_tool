//
//  InputViewController.swift
//  table_generator_tool
//
//  Created by bjunjo on 2021/08/24.
//

import Foundation
import Cocoa

class SelectedSchema
{
    var selected:Bool = false
    var schema:String = ""

    init(selected:Bool, schema:String)
    {
        self.selected = selected
        self.schema = schema
    }
}

class SelectSchemaCellView : NSTableCellView
{
    private var _selectedSchema:SelectedSchema?
    
    public func registerSelectedSchema(_ selectedSchema:SelectedSchema)
    {
        _selectedSchema = selectedSchema
        
        checkbox_schema.title = _selectedSchema?.schema ?? ""
        
        let selected = _selectedSchema?.selected ?? false
        checkbox_schema.state = selected ? .on : .off
    }
    
    @IBOutlet var checkbox_schema: NSButton!
    
    @IBAction func changeCheckSchema(_ sender: Any)
    {
        guard let selectedSchema = _selectedSchema else {
            return
        }
        
        let selected = checkbox_schema.state == .on ? true : false
        if selected == true {
            NotificationCenter.default.post(name: .init("updateSelectedSchema"), object: selectedSchema.schema)
        }
    }
}

class InputViewController : NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate
{
    @IBOutlet var textfield_Identity: NSTextField!
    @IBOutlet var outlineView_Schema: NSOutlineView!
    
    private var schemaList:[SelectedSchema] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        outlineView_Schema.dataSource = self
        outlineView_Schema.delegate = self
    
        NotificationCenter.default.addObserver(self, selector: #selector(updateSelectedSchema(_:)), name: .init("updateSelectedSchema"), object: nil)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    public func updateSchemaList(schemaList:[String]) {
        
        self.schemaList = schemaList.map {
            return SelectedSchema(selected: false, schema: $0)
        }
    
        outlineView_Schema.reloadData()
    }
    
    @objc func updateSelectedSchema(_ notification:NSNotification)
    {
        guard let schemaName = notification.object as? String else {
            return
        }
        
        schemaList.filter {
            $0.schema != schemaName
        }.forEach {
            $0.selected = false
        }
        
        schemaList.filter {
            $0.schema == schemaName
        }.forEach {
            $0.selected = true
        }
        
        outlineView_Schema.reloadData()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
    {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
    {
        return schemaList.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
    {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }
        
        guard let selectSchema = item as? SelectedSchema else {
            return nil
        }
        
        
        switch identifier
        {
        case .init("CheckSchemaCell"):
            
            let schemaCell = outlineView.makeView(withIdentifier: .init("CheckSchemaCell"), owner: self) as? SelectSchemaCellView
            
            schemaCell?.registerSelectedSchema(selectSchema)
            
            schemaCell?.checkbox_schema.title = selectSchema.schema
            return schemaCell
            
        default:
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
    {
        if item == nil {
            return schemaList[index]
        }
        
        return item as! SelectedSchema
    }
    
    
    @IBAction func doOk(_ sender: Any)
    {
        let selectedSchema = schemaList.filter
        {
            $0.selected == true
        }
        
        if selectedSchema.isEmpty == true
        {
            AppDelegate.showWarningAlert(message: "선택 된 schema가 없습니다.")
            return
        }
        
        let sendData:[String:String] = [
            "schema" : selectedSchema[0].schema,
            "identity" : textfield_Identity.stringValue
        ]

        self.view.window?.close()
        
        let notificationName = NSNotification.Name("InputReceive")
        NotificationCenter.default.post(name: notificationName, object: sendData)
    }
    
    @IBAction func doCancel(_ sender: Any) {
    
        self.view.window?.close()
    }
}
