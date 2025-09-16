import SwiftUI
import PhotosUI
import Photos
import MapKit
import CoreLocation

@main
struct ScavengerHuntApp: App {
    var body: some Scene {
        WindowGroup { NavigationStack { TaskListView() } }
    }
}

// MARK: - Model
struct TaskItem: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var details: String
    var isCompleted: Bool
    var imageData: Data?
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), title: String, details: String, isCompleted: Bool = false, imageData: Data? = nil, coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.imageData = imageData
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
    }
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return .init(latitude: lat, longitude: lon)
    }
}

// MARK: - Persistence
enum TaskStore {
    private static let key = "scavenger.tasks.v1"

    static func load() -> [TaskItem] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([TaskItem].self, from: data)) ?? []
    }
    static func save(_ tasks: [TaskItem]) {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Task List (create tasks dynamically)
struct TaskListView: View {
    @State private var tasks: [TaskItem] = TaskStore.load()
    @State private var showingNewTask = false

    var body: some View {
        List {
            if tasks.isEmpty {
                ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap New Task to add one."))
            }
            ForEach(tasks) { task in
                NavigationLink(value: task) {
                    HStack {
                        thumbnail(for: task)
                        VStack(alignment: .leading) {
                            Text(task.title).font(.headline)
                            if !task.details.isEmpty { Text(task.details).foregroundStyle(.secondary).lineLimit(1) }
                        }
                        Spacer()
                        if task.isCompleted { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green) }
                    }
                }
            }
            .onDelete { idx in delete(at: idx) }
        }
        .navigationTitle("Scavenger Hunt")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewTask = true } label: { Label("New Task", systemImage: "plus") }
            }
        }
        .navigationDestination(for: TaskItem.self) { item in
            if let index = tasks.firstIndex(of: item) {
                TaskDetailView(task: $tasks[index])
                    .onChange(of: tasks[index]) { _, _ in persist() }
            } else { Text("Task not found") }
        }
        .sheet(isPresented: $showingNewTask) {
            NewTaskSheet { title, details in
                tasks.insert(TaskItem(title: title, details: details), at: 0)
                persist()
            }
            .presentationDetents([.height(280), .medium])
        }
        .onChange(of: tasks) { _, _ in persist() }
    }

    private func delete(at offsets: IndexSet) { tasks.remove(atOffsets: offsets); persist() }
    private func persist() { TaskStore.save(tasks) }

    private func thumbnail(for task: TaskItem) -> some View {
        Group {
            if let data = task.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                ZStack { RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.15)); Image(systemName: "photo") }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - New Task Sheet
struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    var onCreate: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Details (optional)", text: $details, axis: .vertical)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onCreate(title.trimmingCharacters(in: .whitespaces), details.trimmingCharacters(in: .whitespaces)); dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Task Detail
struct TaskDetailView: View {
    @Binding var task: TaskItem
    @State private var selection: PhotosPickerItem? = nil
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(task.title).font(.title2).bold()
                    if task.isCompleted { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green) }
                }
                if !task.details.isEmpty { Text(task.details).foregroundStyle(.secondary) }

                Group {
                    if let data = task.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack { RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.12)); VStack { Image(systemName: "photo.on.rectangle").font(.system(size: 28)); Text("No photo yet").foregroundStyle(.secondary) } }
                            .frame(height: 180)
                    }
                }

                PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                    Label("Attach Photo", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: selection) { _, newItem in
                    TaskPhotoLoader.load(from: newItem) { payload in
                        guard let payload = payload else { return }
                        task.imageData = payload.imageData
                        if let c = payload.coordinate { task.latitude = c.latitude; task.longitude = c.longitude }
                        task.isCompleted = (task.imageData != nil)
                        if let c = task.coordinate { mapPosition = .region(.init(center: c, span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))) }
                    }
                }

                if let coord = task.coordinate {
                    Map(position: $mapPosition) { Marker("Photo", coordinate: coord) }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onAppear { mapPosition = .region(.init(center: coord, span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))) }
                }
            }
            .padding()
        }
    }
}

// MARK: - Loader: image bytes + GPS via PHAsset
struct PickerPayload { let imageData: Data; let coordinate: CLLocationCoordinate2D? }

enum TaskPhotoLoader {
    static func load(from item: PhotosPickerItem?, completion: @escaping (PickerPayload?) -> Void) {
        guard let item = item else { completion(nil); return }
        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self) {
                var coord: CLLocationCoordinate2D? = nil
                if let id = item.itemIdentifier {
                    let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                    if let asset = fetch.firstObject, let loc = asset.location { coord = loc.coordinate }
                }
                completion(.init(imageData: data, coordinate: coord))
            } else { completion(nil) }
        }
    }
}

// MARK: - Info.plist (String keys)
/*
NSPhotoLibraryUsageDescription = "This app needs photo library access to select a scavenger-hunt photo."
NSCameraUsageDescription = "This app uses the camera to take scavenger-hunt photos." // for stretch
NSLocationWhenInUseUsageDescription = "Location is used to show where your photo was taken on the map."
*/

