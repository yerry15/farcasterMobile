//
//  CastCreationView.swift
//  farcasterFrames
//
//  Created by Jerry Feng on 6/24/24.
//

import SwiftUI

struct CastCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var inputText: String = ""
    
    func sendCast() {
            CastManager.shared.postCast(castMessage: inputText) { result in
                switch result {
                case .success(let result):
                    //
                    self.presentationMode.wrappedValue.dismiss()
                    break
                case .failure(let error):
                    // Handle error
                    print("Failed to post cast: \(error)")
                }
            }
        }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                NavigationLink(destination: ContentView()) {
                    Text("Cancel")
                }
                Spacer()
                Button(action: sendCast) {
                    Text("Send cast")
                        .foregroundColor(.black)
                }
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
                    .padding(.horizontal)
                
                if inputText.isEmpty {
                    Text("Enter your text here...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                }
                
                TextEditor(text: $inputText)
                    .padding()
            }
            .frame(height: 150)
            .padding(.top)
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}

#Preview {
    CastCreationView()
}
