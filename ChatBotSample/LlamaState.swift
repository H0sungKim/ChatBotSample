import Foundation

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
}

@MainActor
class LlamaState: ObservableObject {
    @Published var completionLog = ""
    @Published var inputLog = ""
    @Published var outputLog = ""
    @Published var cacheCleared = false
    let NS_PER_S = 1_000_000_000.0
    
    @Published private(set) var llamaContext: LlamaContext?
    
    var modelLoaded: Bool {
        return llamaContext != nil
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    func loadModel(modelUrl: URL?) throws {
        if let modelUrl {
            print("Loading model...")
//            messageLog += "Loading model...\n"
            llamaContext = try LlamaContext.create_context(path: modelUrl.path())
            print("Loaded model \(modelUrl.lastPathComponent)\n")
//            messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"
        }
    }
    
    func complete(text: String) async {
        guard let llamaContext else {
            print("No llama context")
            return
        }
        // TODO
//        await llamaContext.clear()
        
        completionLog = ""
        inputLog = ""
        outputLog = ""
        
        completionLog = "Processing Completion..."

        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S

        completionLog += "Heat up took \(t_heat)s"
        inputLog += "\(text)"

        Task.detached {
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await MainActor.run {
                    print(result)
                    self.outputLog += "\(result)"
                }
            }

            let t_end = DispatchTime.now().uptimeNanoseconds
            let t_generation = Double(t_end - t_heat_end) / self.NS_PER_S
            let tokens_per_second = Double(await llamaContext.n_len) / t_generation

            await llamaContext.clear()

            await MainActor.run {
                self.completionLog += """
                    \nDone
                    Generated \(tokens_per_second) t/s\n
                    """
            }
        }
    }

//    func bench() async {
//        guard let llamaContext else {
//            return
//        }
//        
//        messageLog += "\n"
//        messageLog += "Running benchmark...\n"
//        messageLog += "Model info: "
//        messageLog += await llamaContext.model_info() + "\n"
//        
//        let t_start = DispatchTime.now().uptimeNanoseconds
//        let _ = await llamaContext.bench(pp: 8, tg: 4, pl: 1) // heat up
//        let t_end = DispatchTime.now().uptimeNanoseconds
//        
//        let t_heat = Double(t_end - t_start) / NS_PER_S
//        messageLog += "Heat up time: \(t_heat) seconds, please wait...\n"
//        
//        // if more than 5 seconds, then we're probably running on a slow device
//        if t_heat > 5.0 {
//            messageLog += "Heat up time is too long, aborting benchmark\n"
//            return
//        }
//
//        let result = await llamaContext.bench(pp: 512, tg: 128, pl: 1, nr: 3)
//
//        messageLog += "\(result)"
//        messageLog += "\n"
//    }

    func clear() async {
        guard let llamaContext else {
            return
        }
        
        await llamaContext.clear()
        inputLog = ""
        outputLog = ""
        completionLog = ""
    }
}
