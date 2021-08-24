//
//  GeneratorConfig.swift
//  table_generator_tool2
//
//  Created by bjunjo on 2021/08/20.
//

import Foundation

struct GeneratorConfigData : Codable
{
    enum CodingKeys: String, CodingKey
    {
        case coreBinPath = "core_bin"
        case workspacePath = "workspace_path"
        case configPath = "config_path"
    }
    
    var coreBinPath:String = ""
    var workspacePath:String = ""
    var configPath:String = ""
    
    var isEnable:Bool {
        if coreBinPath.isEmpty { return false }
        if workspacePath.isEmpty { return false }
        if configPath.isEmpty { return false }
        
        return true
    }
    
    var commandUrl:URL? {
        var commandUrl:URL! = URL(string: self.coreBinPath)
        commandUrl.appendPathComponent("commands")
        commandUrl.appendPathComponent("generator")
    
        if FileManager.default.fileExists(atPath: commandUrl.path) == false
        {
            return nil
        }
        
        return commandUrl
    }
    
    init() {
        coreBinPath = ""
        workspacePath = ""
        configPath = ""
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        coreBinPath = (try? values.decode(String.self, forKey: .coreBinPath)) ?? ""
        workspacePath = (try? values.decode(String.self, forKey: .workspacePath)) ?? ""
        configPath = (try? values.decode(String.self, forKey: .configPath)) ?? ""
    }
}

class GeneratorConfig
{
    private static let _staticConfigPath = ".generatortool"
    
    private static var _configFullPathUrl:URL {
        var configPathUrl = FileManager.default.homeDirectoryForCurrentUser
        configPathUrl.appendPathComponent(GeneratorConfig._staticConfigPath)
        
        return configPathUrl
    }
    
    public static func load() -> GeneratorConfigData
    {
        if FileManager.default.fileExists(atPath: GeneratorConfig._configFullPathUrl.path) == false {
            return GeneratorConfigData()
        }
        
        do
        {
            let data = try Data(contentsOf: GeneratorConfig._configFullPathUrl)
            
            let jsonDecoder = JSONDecoder()
            let configData = try jsonDecoder.decode(GeneratorConfigData.self, from: data)
        
            return configData
        }
        catch
        {
            return GeneratorConfigData()
        }
    }
    
    @discardableResult
    public static func save(configData:GeneratorConfigData) -> Bool
    {
        do
        {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configData)
            
            try data.write(to: GeneratorConfig._configFullPathUrl)
            
            return true
        }
        catch
        {
            return false
        }
    }
}
