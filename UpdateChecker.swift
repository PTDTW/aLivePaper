import Foundation

struct Release: Codable {
    let tagName: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

class UpdateChecker {
    static let currentVersion = "1.0.0" // 當前版本號
    static let repoOwner = "your-github-username"
    static let repoName = "aLivePaper"
    
    static func checkForUpdates(completion: @escaping (Result<Release, Error>) -> Void) {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let release = try JSONDecoder().decode(Release.self, from: data)
                completion(.success(release))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func compareVersions(_ version1: String, _ version2: String) -> Bool {
        let v1 = version1.split(separator: ".")
        let v2 = version2.split(separator: ".")
        
        for i in 0..<min(v1.count, v2.count) {
            let num1 = Int(v1[i]) ?? 0
            let num2 = Int(v2[i]) ?? 0
            if num1 < num2 {
                return true
            } else if num1 > num2 {
                return false
            }
        }
        return v1.count < v2.count
    }
}
