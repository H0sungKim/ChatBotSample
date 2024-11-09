//
//  ContentView.swift
//  ChatBotSample
//
//  Created by 김호성 on 2024.11.09.
//

import SwiftUI

struct ContentView: View {
    @StateObject var llamaState = LlamaState()
    
    @State private var inputText = "Tell me about Hongik University."
    @State private var isLoading = false

    @State private var targetModel: Model = Model(
        name: "Phi-3 Mini-4K-Instruct (Q4, 2.2 GB)",
        url: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf?download=true",
        filename: "Phi-3-mini-4k-instruct-q4.gguf", status: "download"
    )
    
    var body: some View {
        VStack(spacing: 16) {
            modelView
            resultSection
            inputSection
        }
        .padding()
    }
    
    private var modelView: some View {
        VStack(spacing: 8) {
            Text("Model")
            if llamaState.modelLoaded {
                Text(targetModel.name)
                    .frame(maxWidth: .infinity)
            } else {
                DownloadButton(llamaState: llamaState, model: targetModel)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private var inputSection: some View {
        HStack(spacing: 16) {
            TextField("Enter prompt here", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            Button("", systemImage: "paperplane", action: {
                sendMessage()
            })
            .imageScale(.large)
            .disabled(inputText.isEmpty || !llamaState.modelLoaded)
        }
    }

    private var resultSection: some View {
        VStack(spacing: 16) {
            if !llamaState.completionLog.isEmpty {
                ScrollView {
                    Text(llamaState.completionLog)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(Font(UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)))
                        .foregroundColor(Color.white)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 96)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }

            if isLoading {
                ProgressView()
                    .frame(alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    Text(llamaState.outputLog)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func sendMessage() {
        isLoading = true
        Task {
            await llamaState.complete(text: inputText)

            Task { @MainActor in
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
