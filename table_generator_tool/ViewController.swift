//
//  ViewController.swift
//  table_generator_tool2
//
//  Created by bjunjo on 2021/08/19.
//

import Cocoa

enum SelectedTab: String
{
    case schema = "Schema"
    case data = "Data"
}

class FileState
{
    var selected:Bool = false
    var name:String = ""
    
    var schema:String {
        //let splited = name.split(separator: ".")
        let splited = name.components(separatedBy: ".")
        return splited[0]
    }
    
    init(selected:Bool, name:String) {
        self.selected = selected
        self.name = name
    }
}


class ViewController: NSViewController
{

    @IBOutlet var textField_coreBin: NSTextField!
    @IBOutlet var textField_workspace: NSTextField!
    @IBOutlet var textField_config: NSTextField!
    
    @IBOutlet var checkBox_dart: NSButton!
    @IBOutlet var checkBox_csharp: NSButton!
    @IBOutlet var textField_filter: NSTextField!
    
    @IBOutlet var button_refresh: NSButton!
    
    @IBOutlet var tableView_schema: NSTableView!
    @IBOutlet var tableView_data: NSTableView!
    
    @IBOutlet var checkBox_allSelect: NSButton!
    
    //
    private var _selectecTab:SelectedTab = .schema
    
    private var _schemaFileStateList:[FileState] = []
    private var _dataFileStateList:[FileState] = []
    private var _currentFileStateList:[FileState] = []
    
    //
    private var _configData:GeneratorConfigData = GeneratorConfigData()
    
    private var _isEmptyTarget:Bool
    {
        let isDart = checkBox_dart.state == .on ? true : false
        let isCSharp = checkBox_csharp.state == .on ? true : false
        
        return !(isDart || isCSharp)
    }
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveInputNotification(_:)), name: .init("InputReceive"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveCommandProgressNotification(_:)), name: .init("didReceiveCommandProgressNotification"), object: nil)
        
        _initConfigPath()
        
        _doRefresh()
        _filterFileState(filter: "", tabType: SelectedTab.schema)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        NotificationCenter.default.removeObserver(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func _initConfigPath()
    {
        _configData = GeneratorConfig.load()
        
        textField_coreBin.stringValue = _configData.coreBinPath
        textField_workspace.stringValue = _configData.workspacePath
        textField_config.stringValue = _configData.configPath
        
        _checkRefreshButton()
    }
    
    private func _checkRefreshButton()
    {
        var isEnable = true
        if _configData.isEnable == false {
            isEnable = false
        }
        
        button_refresh.isEnabled = isEnable
    }
    
    private func _findDirectory(isDirectoryMode:Bool) -> String
    {
        let dialog = NSOpenPanel()
        dialog.title = "find data workspace"
        dialog.showsResizeIndicator = true
        
        if isDirectoryMode
        {
            dialog.showsHiddenFiles = true
            dialog.allowsMultipleSelection = false
            dialog.canChooseDirectories = true
        }
        else
        {
            dialog.showsHiddenFiles = false
            dialog.allowsMultipleSelection = false
            dialog.canChooseDirectories = false
            
            let fileTypes = ["yaml"]
            dialog.allowedFileTypes = fileTypes
        }

        if dialog.runModal() == .OK {
            return dialog.url?.path ?? ""
        }
        
        return ""
    }

    private func _doRefresh()
    {
        _schemaFileStateList = []
        _dataFileStateList = []
        if _configData.isEnable == false {
            return
        }
        
        do
        {
            let schemaRefreshCmd = SchemaRefreshCommand(_configData)
            let shemaList = try schemaRefreshCmd.doCommand()
            
            let dataRefreshCmd = DataRefreschCommand(_configData)
            let dataList = try dataRefreshCmd.doCommand()
            
            shemaList.forEach
            {
                let name = $0.lastPathComponent
                _schemaFileStateList.append(FileState(selected: false, name: name))
            }
            
            _schemaFileStateList.sort {
                return $0.name < $1.name
            }
            
            dataList.forEach
            {
                let name = $0.lastPathComponent
                _dataFileStateList.append(FileState(selected: false, name: name))
            }
            
            _dataFileStateList.sort {
                return $0.name < $1.name
            }
        }
        catch
        {
            let message = "Refresh 오류\n\(error)"
            
            AppDelegate.showWarningAlert(message: message)
        }
    }
    
    private func _selectedSchemas() -> [String]
    {
        let checkedSchemas:[String] = _schemaFileStateList.filter {
            return $0.selected == true
        }
        .map {
            let components = $0.name.components(separatedBy: ".")
            return components[0]
        }
        
        return checkedSchemas
    }
    
}

extension ViewController : NSTextFieldDelegate
{
    
    func controlTextDidChange(_ obj: Notification)
    {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        
        if textField_filter != textField {
            return;
        }
        
        _filterFileState(filter: textField_filter.stringValue, tabType: _selectecTab)
    }
    
    private func _filterFileState(filter:String, tabType:SelectedTab)
    {
        var currentSelected:[FileState]?
        
        switch tabType
        {
        case .schema:
            currentSelected = _schemaFileStateList
        case .data:
            currentSelected = _dataFileStateList
        }
        
        if currentSelected == nil {
            return
        }
        
        _currentFileStateList = []
        
        currentSelected?.forEach {
            
            if filter.isEmpty == false {
                if $0.name.starts(with: filter) == false {
                    return
                }
            }
            
            _currentFileStateList.append($0)
        }
        
        _checkAllSelectState()
        
        switch tabType
        {
        case .schema:
            tableView_schema.reloadData()
        case .data:
            tableView_data.reloadData()
        }
    }
}

extension ViewController : NSTableViewDataSource, NSTableViewDelegate
{
    private func _updateChangeAllSeleccted(tab:SelectedTab, isSelected:Bool)
    {
        _currentFileStateList.forEach {
            $0.selected = isSelected
            
            _updateFileState(tab: tab, fileState:$0)
        }
        
        switch tab
        {
        case .schema:
            tableView_schema.reloadData()
        case .data:
            tableView_data.reloadData()
        }
    }
    
    private func _updateFileState(tab:SelectedTab, fileState:FileState)
    {
        _checkAllSelectState()
        
        var targetFileStateList:[FileState]!
        switch tab {
        case .schema:
            targetFileStateList = _schemaFileStateList

        case .data:
            targetFileStateList = _dataFileStateList
        }
        
        let findFileStates:[FileState] = targetFileStateList.filter {
            return $0.name == fileState.name
        }
        
        if findFileStates.isEmpty == true {
            return;
        }
        
        findFileStates[0].selected = fileState.selected
        
        if tab == .data {
            _updateCheckGroupDataFileState(fileState:fileState)
            _filterFileState(filter: textField_filter.stringValue, tabType: .data)
        }
    }
    
    private func _updateCheckGroupDataFileState(fileState:FileState)
    {
        _dataFileStateList.forEach {
            if $0.schema == fileState.schema {
                $0.selected = fileState.selected
            }
        }
    }
    
    private func _checkAllSelectState()
    {
        var selectedCount = 0
        _currentFileStateList.forEach {
            selectedCount += $0.selected == true ? 1 : 0
        }
        
        if selectedCount == _currentFileStateList.count {
            checkBox_allSelect.state = .on
        }
        else if selectedCount == 0 {
            checkBox_allSelect.state = .off
        }
        else {
            checkBox_allSelect.state = .mixed
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return _currentFileStateList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
     
        if tableView == tableView_schema
        {
            let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier , owner: self) as? SchemaFileStateTableCellView
        
            let fileState = _currentFileStateList[row]
            
            if tableColumn!.identifier.rawValue == "Selected" {
                cellView?.checkBox_Selected.state = fileState.selected ? .on : .off
            
                cellView?.registerIndex(index: row)
                cellView?.registerSelectedAction {
                    
                    let targetFileState = self._currentFileStateList[$0]
                    
                    targetFileState.selected = $1
                    self._updateFileState(tab: self._selectecTab, fileState: targetFileState)
                }
            }
            else if tableColumn!.identifier.rawValue == "Filename" {
                cellView?.label_fileName.stringValue = fileState.name
            }
            
            return cellView
        }
        else if tableView == tableView_data
        {
            let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier , owner: self) as? DataFileStateTableCellView
        
            let fileState = _currentFileStateList[row]
            
            if tableColumn!.identifier.rawValue == "Selected" {
                cellView?.checkBox_Selected.state = fileState.selected ? .on : .off
            
                cellView?.registerIndex(index: row)
                cellView?.registerSelectedAction {
                    
                    let targetFileState = self._currentFileStateList[$0]
                    
                    targetFileState.selected = $1
                    self._updateFileState(tab: self._selectecTab, fileState: targetFileState)
                }
            }
            else if tableColumn!.identifier.rawValue == "Filename" {
                cellView?.label_fileName.stringValue = fileState.name
            }
            
            return cellView
        }
        
        return nil
    }
}

extension ViewController : NSTabViewDelegate
{
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?)
    {
        guard let identifier = tabViewItem?.identifier as? String else {
            return
        }

        if identifier == SelectedTab.schema.rawValue {
            _selectecTab = .schema
        }
        else if identifier == SelectedTab.data.rawValue {
            _selectecTab = .data
        }
        
        _filterFileState(filter: textField_filter.stringValue, tabType: _selectecTab)
    }
}

// Button 처리들
extension ViewController
{
    
    @IBAction func updateAllSelect(_ sender: Any)
    {
        let nextState = checkBox_allSelect.state
        if nextState == .mixed {
            checkBox_allSelect.state = .on
        }
        
        let isSelected = checkBox_allSelect.state == .on
        ? true : false
        
        _updateChangeAllSeleccted(tab: self._selectecTab, isSelected: isSelected)
    }
    
    @IBAction func doFindPath(_ sender: NSButton)
    {
        // core bin find
        if sender.identifier?.rawValue == "CoreBin" {
            let path = _findDirectory(isDirectoryMode: true)
            if path.isEmpty {
                return;
            }
            
            textField_coreBin.stringValue = path
            _configData.coreBinPath = path
        }
        
        // workspace find
        else if sender.identifier?.rawValue == "Workspace" {
            let path = _findDirectory(isDirectoryMode: true)
            if path.isEmpty {
                return;
            }
            
            textField_workspace.stringValue = path
            _configData.workspacePath = path
        }
        
        // config find
        else if sender.identifier?.rawValue == "Config" {
            let path = _findDirectory(isDirectoryMode: false)
            if path.isEmpty {
                return;
            }
            
            textField_config.stringValue = path
            _configData.configPath = path
        }
        
        GeneratorConfig.save(configData: _configData)
        
        _checkRefreshButton()
    }
    
    @IBAction func doRefresh(_ sender: NSButton)
    {
        _doRefresh()
        _filterFileState(filter: "", tabType: _selectecTab)
    }
    
    @IBAction func doDataExcelGenerate(_ sender: NSButton)
    {
        let inputViewController = self.storyboard?.instantiateController(withIdentifier: "InputViewController") as! InputViewController
        
        self.presentAsSheet(inputViewController)
        
        let schemaNameList:[String] = _schemaFileStateList.map
        {
            return $0.name.components(separatedBy: ".")[0]
        }
        
        inputViewController.updateSchemaList(schemaList: schemaNameList)
    }
    
    @IBAction func doFormatSync(_ sender: NSButton)
    {
        let selectedSchemas:[String] = self._selectedSchemas()
        if selectedSchemas.isEmpty {
            AppDelegate.showWarningAlert(message: "선택 된 Schema가 없습니다.")
            return
        }
        
        do
        {
            let formatSyncCommand = FormatSyncCommand(_configData, viewController:  self)
            try formatSyncCommand.doCommand(schemas: selectedSchemas)
        }
        catch
        {
            let message = "formatSync error\n\(error)"
            AppDelegate.showWarningAlert(message: message)
        }
    }
    
    @IBAction func doEnumGenerate(_ sender: NSButton)
    {
        if self._isEmptyTarget == true {
            AppDelegate.showWarningAlert(message: "Target 언어를 하나라도 선택해 주세요.")
            return;
        }
        
        do
        {
            let isDart = checkBox_dart.state == .on ? true : false
            let isCSharp = checkBox_csharp.state == .on ? true : false
            
            let enumGeneratorCmd = EnumGenerateCommand(_configData, viewController: self)
            try enumGeneratorCmd.doCommand(isDart: isDart, isCSharp: isCSharp)
        }
        catch
        {
            let message = "enumGenerator error\n\(error)"
            AppDelegate.showWarningAlert(message: message)
        }
    }
    
    @IBAction func doClassGenerate(_ sender: NSButton)
    {
        if self._isEmptyTarget == true {
            AppDelegate.showWarningAlert(message: "Target 언어를 하나라도 선택해 주세요.")
            return;
        }
        
        do
        {
            let isDart = checkBox_dart.state == .on ? true : false
            let isCSharp = checkBox_csharp.state == .on ? true : false
            
            let classGeneratorCmd = ClassGeneratorCommand(_configData, viewController: self)
            try classGeneratorCmd.doCommand(isDart: isDart, isCSharp: isCSharp)
        }
        catch
        {
            let message = "classGenerator error\n\(error)"
            AppDelegate.showWarningAlert(message: message)
        }
    }
    
    @IBAction func doDataExtract(_ sender: NSButton)
    {
        var selectedSchemaSet:Set<String> = []
        
        _dataFileStateList.filter {
            $0.selected
        }.forEach {
            selectedSchemaSet.update(with: $0.schema)
        }
        
        let selectedSchemaList:[String] = selectedSchemaSet.map { $0 }
        if selectedSchemaList.isEmpty == true
        {
            AppDelegate.showWarningAlert(message: "선택 된 Data Excel이 없습니다.")
            return
        }
        
        do
        {
            let isDart = checkBox_dart.state == .on ? true : false
            let isCSharp = checkBox_csharp.state == .on ? true : false
           
            let command = DataExtractCommand(_configData, viewController: self)
            try command.doCommand(schemas: selectedSchemaList, isDart: isDart, isCSharp: isCSharp)
        }
        catch
        {
            let message = "data extract error\n\(error)"
            AppDelegate.showWarningAlert(message: message)
        }
            
        
 
    }
}

// Notification
extension ViewController
{
    @objc func didReceiveInputNotification(_ notification:Notification)
    {
        guard let receiveData = notification.object as? [String:String] else {
            return
        }
                
        do
        {
            guard let schema = receiveData["schema"] else {
                return
            }
            
            guard let identity = receiveData["identity"] else {
                return
            }
            
            if identity.isEmpty == false
            {
                let regex = try NSRegularExpression(pattern: "^[0-9A-Za-z.]+[0-9A-Za-z]$")
                
                guard regex.firstMatch(in: identity, options: [], range: NSRange(location: 0, length: identity.count)) != nil else
                {
                    AppDelegate.showWarningAlert(message: "\(identity)는 숫자, 영어, . 으로만 구성해야 합니다.")
                    return
                }
            }
            
            let commmand = NewDataExcelGenerateCommand(_configData, viewController: self)
            
            try commmand.doCommand(schema: schema, identity: identity)
        }
        catch
        {
            AppDelegate.showWarningAlert(message: "Data Excel 에러\n\(error)")
        }
    }
    
    @objc func didReceiveCommandProgressNotification(_ notification:Notification)
    {
        guard let commandName = notification.object as? String else {
            return
        }
        
        let targetCommandName = String(describing: NewDataExcelGenerateCommand.self)
        
        switch commandName
        {
        case targetCommandName:
            _doRefresh()
        default:
            break
        }
    }
}
