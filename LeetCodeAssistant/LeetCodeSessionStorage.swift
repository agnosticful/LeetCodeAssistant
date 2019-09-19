import Foundation

class LeetCodeSessionStorage {
    private let applicationTag: Data
    private let account = "leetCodeSessionToken"
    
    init(applicationTag: String) {
        self.applicationTag = applicationTag.data(using: .utf8)!
    }
    
    func load() -> String? {
        let query = [
            kSecMatchLimit  : kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecReturnData: true,
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        var item: CFTypeRef?
        guard SecItemCopyMatching(query, &item) == errSecSuccess else {
            debugPrint("there's no token saved")
            
            return nil
        }

        let existingItem = item as? [String: Any]
        let value = existingItem?[kSecValueData as String] as? Data
        
        guard let data = value else {
            debugPrint("failed to cast the value in keychain to data")
            
            return nil
        }
        
        guard let sessionToken = String(data: data, encoding: .utf8) else {
            debugPrint("failed to cast the data from keychain to string")
            
            return nil
        }

        return sessionToken
    }
    
    func save(_ sessionToken: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecValueData: sessionToken.data(using: .utf8)!
        ] as CFDictionary
        
        if SecItemDelete(query) != errSecSuccess {
            debugPrint("there's no session token saved")
        }
        
        guard SecItemAdd(query, nil) == errSecSuccess else {
            debugPrint("failed to save a session token")
            
            return
        }
        
        debugPrint("succecessful to save a session token")
    }
    
    func delete() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        guard SecItemDelete(query) == errSecSuccess else {
            debugPrint("failed to delete the session token")
            
            return
        }
        
        debugPrint("succecessful to delete the session token")
    }

    static let shared = LeetCodeSessionStorage(applicationTag: "leetcode-assistant.axross.app")
}

