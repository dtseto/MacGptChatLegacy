//
//  ContentView.swift
//  MacGptChatLegacy
//
//  Created by User2 on 11/8/24.
//
// creates the view to login to openai using api key and change it
// also code to use the openai api code
// includes a debug logging view to see the api
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var apiKey: String = ""
    @State private var message: String = ""
    @State private var conversation: String = ""
    @State private var debugLog: String = "Debug Log:\n"
    @State private var isLoading: Bool = false
    @State private var showDebug: Bool = false
    @State private var showAPIKeyInput: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            if showAPIKeyInput {
                // API Key Input View
                VStack(spacing: 15) {
                    Text("OpenAI API Key Required")
                        .font(.headline)
                    
                    Text("Enter your OpenAI API key to start chatting. Note you need an OpenAI api key either in free trial or in pay as you go monthly billing. Otherwise it may give a rate limit exceeded error.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    SecureField("Enter API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 400)
                    
                    Button("Start Chat") {
                        if !apiKey.isEmpty {
                            showAPIKeyInput = false
                            appendToLog("API Key set, length: \(apiKey.count) characters")
                        }
                    }
                    .disabled(apiKey.isEmpty)
                }
                .padding()
                
            } else {
                // Main Chat Interface
                // Toggle for debug view
                Toggle("Show Debug Log", isOn: $showDebug)
                    .padding(.horizontal)
                
                if showDebug {
                    // Debug log area
                    ScrollView {
                        Text(debugLog)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 200)
                    .border(Color.gray)
                }
                
                // Chat history area
                ScrollView {
                    Text(conversation)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: showDebug ? 150 : 300)
                .border(Color.gray)
                
                // Loading indicator
                if isLoading {
                    Text("Loading...")
                        .foregroundColor(.gray)
                }
                
                // Input area
                HStack {
                    TextField("Enter message", text: $message, onCommit: {
                        if !message.isEmpty && !isLoading {
                            sendMessage()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(isLoading || message.isEmpty)
                }
                .padding()
                
                // API Key management button
                Button("Change API Key") {
                    showAPIKeyInput = true
                    apiKey = ""
                    appendToLog("API Key reset requested")
                }
                .foregroundColor(.blue)
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func appendToLog(_ text: String) {
        debugLog += text + "\n"
        print(text)
    }
    
    func sendMessage() {
        guard !message.isEmpty else { return }
        
        let userMessage = message
        conversation += "You: \(userMessage)\n"
        appendToLog("Sending message: \(userMessage)")
        message = ""
        isLoading = true
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            appendToLog("Error: Invalid URL")
            conversation += "Error: Invalid URL\n"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            appendToLog("Request created successfully")
        } catch {
            appendToLog("Error creating request: \(error.localizedDescription)")
            conversation += "Error: Could not create request\n"
            isLoading = false
            return
        }
        
        appendToLog("Starting network request...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    appendToLog("Network error: \(error.localizedDescription)")
                    conversation += "Error: \(error.localizedDescription)\n"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    appendToLog("Error: Invalid response type")
                    conversation += "Error: Invalid response\n"
                    return
                }
                
                appendToLog("Response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = "Error: Server returned status \(httpResponse.statusCode)"
                    if httpResponse.statusCode == 401 {
                        conversation += "Error: Invalid API key. Please check your API key and try again.\n"
                        showAPIKeyInput = true  // Show API key input if authentication fails
                    } else {
                        conversation += "\(errorMessage)\n"
                    }
                    appendToLog(errorMessage)
                    return
                }
                
                guard let data = data else {
                    appendToLog("Error: No data received")
                    conversation += "Error: No data received\n"
                    return
                }
                
                // Log raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    appendToLog("Raw response: \(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        appendToLog("Parsed response: \(content)")
                        conversation += "Assistant: \(content)\n\n"
                    } else {
                        appendToLog("Error: Could not parse response structure")
                        conversation += "Error: Could not parse response\n"
                    }
                } catch {
                    appendToLog("JSON parsing error: \(error.localizedDescription)")
                    conversation += "Error: \(error.localizedDescription)\n"
                }
            }
        }.resume()
        
        appendToLog("Network request initiated")
    }
}
