import AxeptioSDK
import Foundation

struct ConfigurationData: Codable, Equatable, RawRepresentable {
    private enum CodingKeys: String, CodingKey {
        case projectId
        case bearerToken
        case flowType
        case appVersion
        case environment
        case customConfigId
    }

    let projectId: String
    let bearerToken: String
    let flowType: CookieFlowType
    let appVersion: String
    let environment: SDKEnvironment
    let customConfigId: String?

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return result
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(bearerToken, forKey: .bearerToken)
        try container.encode(flowType.rawValue, forKey: .flowType)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(environment.rawValue, forKey: .environment)
        try container.encode(customConfigId, forKey: .customConfigId)
    }

    init(
        projectId: String,
        bearerToken: String,
        flowType: CookieFlowType,
        appVersion: String,
        environment: SDKEnvironment,
        customConfigId: String? = nil
    ) {
        self.projectId = projectId
        self.bearerToken = bearerToken
        self.flowType = flowType
        self.appVersion = appVersion
        self.environment = environment
        self.customConfigId = customConfigId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decode(String.self, forKey: .projectId)
        bearerToken = try container.decode(String.self, forKey: .bearerToken)
        let flowTypeRawValue = try container.decodeIfPresent(String.self, forKey: .flowType)
        flowType = flowTypeRawValue.flatMap(CookieFlowType.init(rawValue:)) ?? Defaults.flowType
        appVersion = try container.decode(String.self, forKey: .appVersion)
        let environmentRawValue = try container.decodeIfPresent(String.self, forKey: .environment)
        environment = environmentRawValue.flatMap(SDKEnvironment.init(rawValue:)) ?? Defaults.environment
        customConfigId = try container.decodeIfPresent(String.self, forKey: .customConfigId)
    }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(ConfigurationData.self, from: data)
        else {
            return nil
        }
        self = result
    }
}

extension ConfigurationData {
    static let `default` = ConfigurationData(
        projectId: Defaults.projectId,
        bearerToken: Defaults.bearerToken,
        flowType: Defaults.flowType,
        appVersion: Defaults.appVersion,
        environment: Defaults.environment
    )

    var localConfiguration: LocalConfigurationModel {
        let cookiesConfiguration: CookieConfigurationSource = if let customConfigId {
            .configId(customConfigId)
        } else {
            .flowType(flowType)
        }

        return LocalConfigurationModel(
            projectId: projectId,
            version: appVersion,
            authToken: bearerToken,
            environment: environment,
            cookiesConfiguration: cookiesConfiguration
        )
    }
}
