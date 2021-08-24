//
//  GeneratorCommands.swift
//  table_generator_tool
//
//  Created by bjunjo on 2021/08/23.
//

import Foundation

class Command
{
    fileprivate let _configData:GeneratorConfigData
    
    public func getCoreCommand() throws -> CoreCommand {
        
        guard let commandUrl = _configData.commandUrl else {
            throw CoreCommandError.launchNotFound
        }
        
        return try CoreCommand(launcherUrl: commandUrl)
    }
    
    public var baseArguments:[String] {
        return [
            "--workspace=\"\(_configData.workspacePath)\"",
            "--config=\"\(_configData.configPath)\"",
            "--json",
        ]
    }
    
    init(_ configData:GeneratorConfigData) {
        _configData = configData
    }
}

class RefershCommand : Command
{
    fileprivate func _refreshList(args:[String]) throws ->[URL]
    {
        let command = try self.getCoreCommand()
        try command.runShell(args:args)
        command.WaitforShell()
        
        if command.resultCode != 0 {
            
            var message = "code = \(command.resultCode)\n";
            message += command.output
            
            throw CoreCommandError.commandRunError(message)
        }
        
        let data = command.output.data(using: .utf8)
        let json = try? JSONSerialization.jsonObject(with: data!, options: [])
        
        // Json 형태가 아니므로 Error
        if json == nil {
            throw CoreCommandError.notJson(command.output)
        }
        
        guard let list = json as? [String] else {
            throw CoreCommandError.notMatchingJsonFormat
        }
        
        return list.map {
            URL(string: $0)!
        }
    }
}

class SchemaRefreshCommand: RefershCommand
{
    public func doCommand() throws -> [URL]
    {
        var args:[String] = self.baseArguments
        args.append("find")
        args.append("--schema")
        
        do
        {
            return try _refreshList(args:args)
        }
        catch
        {
            throw error
        }
    }
}

class DataRefreschCommand : RefershCommand
{
    public func doCommand() throws -> [URL]
    {
        var args:[String] = self.baseArguments
        args.append("find")
        args.append("--data")
        
        do
        {
            return try _refreshList(args:args)
        }
        catch
        {
            throw error
        }
    }
}

class ProgressCommand : Command
{
    fileprivate let _viewController:ViewController
    fileprivate var _progressViewController:ProgressViewContorller?
    
    fileprivate var commandName:String
    {
        let fullName = String(describing: self)
        let components:[String] = fullName.components(separatedBy: ".")
        
        return components[components.count - 1]
    }
    
    init(_ config:GeneratorConfigData, viewController:ViewController)
    {
        _viewController = viewController
        super.init(config)
        
        _progressViewController = _viewController.storyboard?.instantiateController(withIdentifier: "ProgressViewController") as? ProgressViewContorller
        
        _viewController.presentAsSheet(_progressViewController!)
        
        
        _progressViewController?.registerCommandName(commandName: self.commandName)
    }
    
    public override func getCoreCommand() throws -> CoreCommand
    {
        let coreCommand = try super.getCoreCommand()
    
        coreCommand.registerErrorMessageHandler {
            self.progressViewController?.updateOutput(output: $0)
        }
        
        return coreCommand
    }
    
    fileprivate var progressViewController:ProgressViewContorller?
    {
        return _progressViewController
    }
    
    fileprivate func _registerCoreCommand(coreCommand:CoreCommand, autoTerminate:Bool = true)
    {
        coreCommand.registerOutputMessageHandler
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
                    
                    self.progressViewController?.progressUpdate(progress: progress, progressText: progress_text)
                    
                    
                    
                    self.progressViewController?.updateOutput(output: progress_text)
                    
                    return
                }
                else if state == "error"
                {
                    
                    guard let error = stateMap["error"] as? String else {
                        return
                    }
                    
                    self.progressViewController?.updateOutput(output: error)
                }
            }
            else if let list = $0 as? [String] {
                self.progressViewController?.updateOutput(output: list.joined(separator: "\n"))
            }
            else if let str = $0 as? String {
                self.progressViewController?.updateOutput(output: str)
            }
        }
        
        if autoTerminate == true
        {
            coreCommand.registerTerminateHandler { ret in
                self.progressViewController?.progressComplete()
            }
        }
    }
}

class ClassGeneratorCommand : ProgressCommand
{
    public func doCommand(isDart:Bool, isCSharp:Bool) throws
    {
        defer {
            _progressViewController?.progressComplete()
        }
        
        let coreCommand = try self.getCoreCommand()
        
        _registerCoreCommand(coreCommand: coreCommand)
        
        var args:[String] = self.baseArguments
        args.append("class-generate")
        
        if isDart {
            args.append("--dart")
        }
        
        if isCSharp {
            args.append("--csharp")
        }
        
        try coreCommand.runShell(args: args)
    }
}

class FormatSyncCommand : ProgressCommand
{
    public func doCommand(schemas:[String]) throws
    {
        defer {
            _progressViewController?.progressComplete()
        }
        
        for schema in schemas
        {
            let coreCommand = try self.getCoreCommand()
            
            _registerCoreCommand(coreCommand: coreCommand, autoTerminate: false)
            
            var args:[String] = self.baseArguments
            args.append("schema-sync")
            args.append("--schema=\(schema)")
            
            try coreCommand.runShell(args: args)
            coreCommand.WaitforShell()
        }
    }
}

class EnumGenerateCommand : ProgressCommand
{
    public func doCommand(isDart:Bool, isCSharp:Bool) throws
    {
        let coreCommand = try self.getCoreCommand()
        
        _registerCoreCommand(coreCommand: coreCommand)
        
        var args:[String] = self.baseArguments
        args.append("enum-generate")
        
        if isDart {
            args.append("--dart")
        }
        
        if isCSharp {
            args.append("--csharp")
        }
        
        try coreCommand.runShell(args: args)
    }
}

class NewDataExcelGenerateCommand : ProgressCommand
{
    public func doCommand(schema:String, identity:String) throws
    {
        let coreCommand = try self.getCoreCommand()
        
        _registerCoreCommand(coreCommand: coreCommand)
        
        var args:[String] = self.baseArguments
        args.append("schema-new-data")
        args.append("--schema=\(schema)")
        args.append("--identity=\(identity)")
        
        try coreCommand.runShell(args: args)
    }
}

class DataExtractCommand : ProgressCommand
{
    public func doCommand(schemas:[String], isDart:Bool, isCSharp:Bool) throws
    {
        defer {
            _progressViewController?.progressComplete()
        }
        
        for schema in schemas
        {
            let coreCommand = try self.getCoreCommand()
            
            _registerCoreCommand(coreCommand: coreCommand, autoTerminate: false)
            
            var args:[String] = self.baseArguments
            args.append("data-generate")
            args.append("--schema=\(schema)")
            
            if isDart == true  {
                args.append("--dart")
            }
            
            if isCSharp == true  {
                args.append("--csharp")
            }
            
            try coreCommand.runShell(args: args)
            coreCommand.WaitforShell()
        }
    }
}
