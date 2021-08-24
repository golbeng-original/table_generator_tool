//
//  core_command.swfit.swift
//  table_generator_tool
//
//  Created by bjunjo on 2021/08/19.
//

import Foundation
import Cocoa
import SwiftUI
import Combine

enum CoreCommandError : Error
{
    case launchNotFound
    case commandRunError(String)
    case notJson(String)
    case notMatchingJsonFormat
}

typealias TerminateHandler = (_:Int)->Void
typealias JsonMessageHandler = (_:Any)->Void
typealias ErrorMessageHandler = ( _:String)->Void


class CoreCommand
{
    private var _process:Process?
    
    private let _launcherUrl:URL
    private var _terminateHandler:TerminateHandler?
    private var _jsonMessageHandler:JsonMessageHandler?
    private var _errorMessageHandler:ErrorMessageHandler?
    
    private var _output:String = ""
    public var output:String {
        return _output
    }
    
    private var _resultCode:Int = 0
    public var resultCode:Int {
        return _resultCode
    }
    
    init(launcherUrl:URL) throws
    {
        _launcherUrl = launcherUrl
        
        if FileManager.default.fileExists(atPath: _launcherUrl.path) == false
        {
            throw CoreCommandError.launchNotFound
        }
    }
    
    private func _updateClassifyOutput(output:String)
    {
        if output.isEmpty == true {
            return
        }
        
        _output += output
        
        let components = output.components(separatedBy: "\n")
        for component in components
        {
            if component.isEmpty == true {
                continue
            }
            
            do
            {
                let json = try JSONSerialization.jsonObject(with: component.data(using: .utf8)!, options: [])
                
                _jsonMessageHandler?(json)
            }
            catch
            {
                _errorMessageHandler?(component)
            }
        }
    }
    
    public func registerTerminateHandler(handler:@escaping TerminateHandler) {
        _terminateHandler = handler
    }
    
    public func registerOutputMessageHandler(handler:@escaping JsonMessageHandler) {
        _jsonMessageHandler = handler
    }
    
    public func registerErrorMessageHandler(handler:@escaping ErrorMessageHandler) {
        _errorMessageHandler = handler
    }
    
    public func StopShell()
    {
        guard let process = _process else {
            return
        }
        
        if process.isRunning == false {
            return
        }
        
        process.terminate()
    }
    
    public func WaitforShell()
    {
        if _process == nil {
            return
        }
        
        if _process!.isRunning == false {
            return
        }
     
        _process!.waitUntilExit()
        print("waiting end!!")
    }
    
    public func runShell(args:[String] = []) throws
    {
        _process = Process()
        _process!.launchPath = _launcherUrl.path
        _process!.arguments = args
                
        let pipe = Pipe()
        _process!.standardOutput = pipe
        
        do
        {
            pipe.fileHandleForReading.readabilityHandler = { (handler) in
                let outMessage = String(data:handler.availableData, encoding: .utf8)
                self._updateClassifyOutput(output: outMessage!)
            }
            
            _process!.terminationHandler = { (inProcess) in
                let ret = Int(inProcess.terminationStatus)
    
                self._resultCode = ret
                self._terminateHandler?(ret)
                
                self._terminateHandler = nil
                self._jsonMessageHandler = nil
                self._errorMessageHandler = nil
                
                //self._process == nil
                print("terminated!!!")
            }
            
            try _process!.run()
            print("run!!!")
        }
        catch {
            throw error
        }
    }
}
