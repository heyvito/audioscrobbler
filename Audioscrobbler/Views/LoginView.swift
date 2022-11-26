//
//  Login.swift
//  Audioscrobbler
//
//  Created by Victor Gama on 24/11/2022.
//

import SwiftUI

struct LoginView: View {
    @State var showLoginSheet: Bool = false
    @State var loginState = WaitingLoginView.Status.generatingToken
    @EnvironmentObject var ws: WebService
    @State var showErrorDialog: Bool = false
    @State var errorDialogTitle: String = ""
    @State var errorDialogText: String = ""
    
    func showError(title: String, message: String) {
        DispatchQueue.main.async {
            showLoginSheet = false
            errorDialogTitle = title
            errorDialogText = message
            showErrorDialog = true
        }
    }
    
    func showError(error: Error)  {
        DispatchQueue.main.async {
            showLoginSheet = false
            errorDialogTitle = "The operation could not be completed"
            errorDialogText = error.localizedDescription
            showErrorDialog = true
        }
    }
    
    func updateLoginState(_ new: WaitingLoginView.Status) {
        DispatchQueue.main.async {
            loginState = new
        }
    }
    
    func doLogin() async {
        let token: String
        let targetURL: URL
        do {
            (token, targetURL) = try await ws.prepareAuthenticationToken()
            NSWorkspace.shared.open(targetURL)
        } catch WebService.WSError.ResponseMissingKey(_), WebService.WSError.InvalidResponseType, WebService.WSError.HTTPError(_, _), WebService.WSError.UnexpectedResponse {
            self.showError(title: "Error communicating with Last.fm", message: "An error prevented the operation from completing. Please try again later.")
            return
        } catch {
            showError(error: error)
            return
        }
        
        
        updateLoginState(.waitingForLogin)
        var session: WebService.AuthenticationResult?
        while showLoginSheet {
            guard ((try? await Task.sleep(nanoseconds: 2_000_000_000)) != nil) else { return }
            do {
                session = try await ws.getAuthenticationResult(token: token)
                break
            } catch WebService.WSError.APIError(let err) {
                if err.code == 14 {
                    continue
                }
                self.showError(title: "Error communicating with Last.fm", message: err.message)
                return
            } catch {
                showError(error: error)
                return
            }
        }
        
        if !showLoginSheet {
            return
        }
        
        guard let session = session else { abort() }
        
        updateLoginState(.finishingUp)

        var userData: WebService.UserInfo?
        do {
            userData = try await ws.getUserInfo(token: session.key)
        } catch WebService.WSError.APIError(let err) {
            self.showError(title: "Error communicating with Last.fm", message: err.message)
            return
        } catch {
            showError(error: error)
            return
        }

        if !showLoginSheet {
            return
        }

        Defaults.shared.url = userData?.url
        let userImage = userData?.images.first { $0.size == "medium" } ??
        userData?.images.first

        if let u = userImage {
            Defaults.shared.picture = try? await ws.getUserImage(u)
        }
        Defaults.shared.pro = session.subscriber
        Defaults.shared.name = session.name
        Defaults.shared.token = session.key
        
        DispatchQueue.main.async {
            showLoginSheet = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView()
            Divider()
            VStack(alignment: .leading) {
                Text("Welcome to Audioscrobbler!")
                    .font(.largeTitle)
                Text("This application allows you to scrobble tracks from Apple's Music app. To begin, click the button below to login with your Last.fm account.")
                    .lineLimit(nil)
                Spacer()
                Divider()
                Button("Login") {
                    loginState = .generatingToken
                    showLoginSheet = true
                    Task {
                        await doLogin()
                    }
                }
            }.padding()
                .sheet(isPresented: $showLoginSheet) {
                    WaitingLoginView(status: $loginState, onCancel: {
                        showLoginSheet = false
                    })
                }
                .alert(isPresented: $showErrorDialog) {
                    Alert(
                        title: Text(errorDialogTitle),
                        message: Text(errorDialogText),
                        dismissButton: .default(Text("OK"))
                    )
                }
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
