import SwiftUI

struct AccountView: View {
    @State public var user: User = User(fid: 0, signerKey: "")
    func loadUserData() {
        let loadedUser: User = UserManager.shared.getUserData()
        user = loadedUser
    }
    
    func poll(token: String) {
        UserManager.shared.pollForApproval(token: token) { result in
                    switch result {
                    case .success(let state):
                        if state != "completed" {
                            poll(token: token)
                        } else {
                            loadUserData()
                        }
                        break
                    case .failure(let error):
                        // Handle error
                        print("Failed to sign in: \(error)")
                    }
                }
    }
    
    func signIn() {
        print("Sign-in button click")
        UserManager.shared.signInWithWarpcast() { result in
                switch result {
                case .success(let signInResponse):
                    UIApplication.shared.open(URL(string: signInResponse.deepLinkUrl)!)
                    poll(token: signInResponse.token)
                    break
                case .failure(let error):
                    print("Failed to sign in: \(error)")
                }
            }
        }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "signing_key")
        UserDefaults.standard.removeObject(forKey: "fid")
        UserDefaults.standard.removeObject(forKey: "signer_approved")
    }
    var body: some View {
        VStack {
            if user.fid == 0 {
                VStack {
                    Text("Welcome")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    Text("Let's get signed in")
                    Button(action: signIn) {
                        Text("Sign in with Warpcast")
                    }
                }
            } else {
                Text(String(UserManager.shared.getUserData().fid))
                Button(action: signOut) {
                    Text("Sign out")
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
}

#Preview {
    AccountView()
}
