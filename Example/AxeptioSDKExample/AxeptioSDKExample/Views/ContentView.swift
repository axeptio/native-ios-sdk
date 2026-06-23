import AxeptioSDK
import FamilyControls
import HealthKit
import Photos
import SwiftUI

struct ContentView: View {
    @AppStorage("configuration")
    private var configuration: ConfigurationData = .default

    @State private var showConfigurationModal = false
    @State private var sdkEntryPoint: RootEntryPointType?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Example App")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            action: { showConfigurationModal = true },
                            label: { Image(systemName: "gearshape") }
                        )
                    }
                }
                .task {
                    await initializeSDK()

                    if await Axeptio.shared.shouldDisplayConsents {
                        sdkEntryPoint = .cookieAndAttOnly
                    }
                }
                .onChange(of: configuration) {
                    Task { await initializeSDK() }
                }
        }
        .fullScreenCover(item: $sdkEntryPoint) {
            RootView(entryPoint: $0)
        }
        .sheet(isPresented: $showConfigurationModal) {
            ConfigurationView(currentConfiguration: configuration) {
                configuration = $0
            }
        }
    }

    private var content: some View {
        List {
            Section {
                getCell(for: .openMainFlow)
                getCell(for: .openCookieFlow)
                getCell(for: .openPermissionsFlow)
            } header: {
                Text("Flows")
            }
        }
        .listStyle(.plain)
    }

    private func getCell(for type: ActionType) -> some View {
        ActionCellView(
            type: type,
            didTapCell: { sdkEntryPoint = type.entryPoint }
        )
    }

    private func initializeSDK() async {
        await Axeptio.shared.initialize(
            with: configuration.localConfiguration,
            permissions: [
                .init(
                    type: .notifications(options: [.alert, .badge, .sound]),
                    description: "In order to improve your experience, we need to count and measure events on this website."
                ),
                .init(
                    type: .camera,
                    description: "Our mission is to help you have the most delightful experience while browsing our pages."
                ),
                .init(
                    type: .microphone,
                    description: "Any website can lag or crash. To limit these kinds of incidents, we would like to load third-party scripts that enable us to monitor performances and errors occurring during your visit."
                ),
                .init(
                    type: .location,
                    title: "Nearby places",
                    description: "CRM are tools used by our team to handle lead qualification and customer relationship management. With the help of these tools, we're able to keep track of our prospects precisely and effectively."
                ),
                .init(
                    type: .contacts,
                    description: "Reads and saves contacts to suggest friends, auto-fill details, and enable in-app messaging."
                ),
                .init(
                    type: .photoLibrary(accessLevel: .readWrite),
                    description: "Accesses your photos and videos to save and let you share media."
                ),
                .init(
                    type: .calendar(accessLevel: .full),
                    description: "Reads your calendar to help with scheduling, check your availability, and create new meetings."
                ),
                .init(
                    type: .bluetooth,
                    description: "Detects and connects to nearby Bluetooth devices and accessories."
                ),
                .init(
                    type: .fitness,
                    description: "Detects when you're walking, running, or cycling to track workouts automatically."
                ),
                .init(
                    type: .health(
                        read: [
                            .category(.appetiteChanges),
                            .quantity(.appleExerciseTime),
                            .quantity(.appleMoveTime),
                            .workout,
                            .characteristic(.bloodType),
                            .clinical(.allergyRecord)
                        ],
                        share: [
                            .category(.acne),
                            .quantity(.flightsClimbed),
                            .category(.bladderIncontinence),
                            .workout
                        ]
                    ),
                    description: "Reads and stores health data like steps, heart rate, and sleep to track your wellbeing."
                ),
                .init(
                    type: .familyControls(member: .individual),
                    description: "Accesses your screen time usage to help you manage your digital habits."
                )
            ],
            onConsentsUpdated: nil,
            onError: { _ in }
        )
    }
}

#Preview {
    ContentView()
}
