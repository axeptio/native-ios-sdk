import AxeptioSDK
import SwiftUI

struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var projectId: String
    @State private var bearerToken: String
    @State private var selectedFlowType: CookieFlowType
    @State private var appVersion: String
    @State private var selectedEnvironment: SDKEnvironment
    @State private var customConfigId: String

    @FocusState private var focusedField: ConfigurationField?

    private let didTapSave: (ConfigurationData) -> ()

    init(
        currentConfiguration: ConfigurationData,
        didTapSave: @escaping (ConfigurationData) -> ()
    ) {
        _projectId = State(initialValue: currentConfiguration.projectId)
        _bearerToken = State(initialValue: currentConfiguration.bearerToken)
        _selectedFlowType = State(initialValue: currentConfiguration.flowType)
        _appVersion = State(initialValue: currentConfiguration.appVersion)
        _selectedEnvironment = State(initialValue: currentConfiguration.environment)
        _customConfigId = State(initialValue: currentConfiguration.customConfigId ?? "")
        self.didTapSave = didTapSave
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Configuration")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            didTapSaveConfiguration()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }

    private var content: some View {
        Form {
            projectIdSection
            bearerTokenSection
            flowTypeSection
            appVersionSection
            environmentSection
            customConfigIdSection
        }
    }

    private var projectIdSection: some View {
        Section("Project ID") {
            TextField("Project ID", text: $projectId)
                .focused($focusedField, equals: .projectId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .scrollDismissesKeyboard(.interactively)
                .onSubmit { focusedField = nil }
        }
    }

    private var bearerTokenSection: some View {
        Section("Bearer Token") {
            TextField("Bearer Token", text: $bearerToken)
                .focused($focusedField, equals: .bearerToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .scrollDismissesKeyboard(.interactively)
                .onSubmit { focusedField = nil }
        }
    }

    private var flowTypeSection: some View {
        Section {
            if customConfigId.isEmpty {
                Picker(selection: $selectedFlowType) {
                    ForEach(CookieFlowType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                } label: {
                    Text("Select type")
                }
            } else {
                Text("Not applicable")
                    .opacity(0.7)
            }
        } header: {
            Text("Cookie flow type")
        } footer: {
            if !customConfigId.isEmpty {
                Text(
                    "When custom configurationId is provided, cookie flow type is selected automatically. Provided type is then ignored."
                )
            }
        }
    }

    private var appVersionSection: some View {
        Section("App Version") {
            TextField("1.2.3", text: $appVersion)
                .focused($focusedField, equals: .appVersion)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.numbersAndPunctuation)
                .submitLabel(.done)
                .scrollDismissesKeyboard(.interactively)
                .onSubmit { focusedField = nil }
        }
    }

    private var environmentSection: some View {
        Section("Environment") {
            Picker(selection: $selectedEnvironment) {
                ForEach(SDKEnvironment.allCases) { environment in
                    Text(environment.title).tag(environment)
                }
            } label: {
                Text("Select environment")
            }
        }
    }

    private var customConfigIdSection: some View {
        Section {
            TextField("Optional", text: $customConfigId)
                .focused($focusedField, equals: .customConfigId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .scrollDismissesKeyboard(.interactively)
                .onSubmit { focusedField = nil }
        } header: {
            Text("Configuration ID")
        } footer: {
            Text(
                "When set, ignores provied flow type and selects it to match provided configuration."
            )
        }
    }

    private func didTapSaveConfiguration() {
        let updatedConfigId = customConfigId.isEmpty ? nil : customConfigId
        let updatedConfiguration = ConfigurationData(
            projectId: projectId,
            bearerToken: bearerToken,
            flowType: selectedFlowType,
            appVersion: appVersion,
            environment: selectedEnvironment,
            customConfigId: updatedConfigId
        )
        didTapSave(updatedConfiguration)
    }
}

#Preview {
    ConfigurationView(currentConfiguration: .default) { _ in }
}
