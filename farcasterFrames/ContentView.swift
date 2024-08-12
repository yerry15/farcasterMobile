import SwiftUI
import SwiftData

struct ContentView: View {
    @State public var casts: [Cast] = []
    
    func loadCasts() {
        CastManager.shared.fetchCasts() { result in
            switch result {
            case .success(let casts):
                self.casts = casts
            case .failure(let error):
                // Handle error
                print("Failed to fetch casts: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: AccountView()) {
                       Image(systemName: "person.crop.circle.fill")
                       .resizable()
                       .aspectRatio(contentMode: .fit)
                       .frame(width: 30, height: 30)
                       .clipShape(Circle())
                       .padding()
                       .foregroundColor(.black)
                    }
                }
                ScrollView(.vertical) {
                    ForEach(casts, id: \.id) { cast in
                        LazyVStack(spacing: 0) {
                            HStack {
                                AsyncImage(url: URL(string:cast.pfpUrl))
                                    .frame(width:40, height:40)
                                    .clipShape(Circle())
                                Text("@\(cast.username)")
                                Spacer()
                            }
                            Text(cast.castText)
                        }
                        .padding(.top)
                        
                    }
                }
                Spacer()
            }
            .padding()
            .onAppear {
                loadCasts()
            }
            .overlay(
                GeometryReader { geometry in
                    Button(action: {
                        //  Open cast form
                    }) {
                        NavigationLink(destination: CastCreationView()) {
                          Image(systemName: "plus")
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                          .frame(width: 30, height: 30)
                          .clipShape(Circle())
                          .foregroundColor(Color.black)
                          .padding()
                        }
                    }
                    .frame(width: geometry.size.width - 25, height: geometry.size.height - 25, alignment: .bottomTrailing)
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
