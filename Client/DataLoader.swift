import UIKit

class DataLoader: NSObject {

    static let sharedInstance = DataLoader()

    private var callbacks: [String: (_ data: Data?) -> Void] = [:]

    func load(url: URL, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        URLSession.dataSession.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                dataCallback?(data)
            }
        }.resume()
    }

    func load(key: String, url: URL, force: Bool = false, _ dataCallback: ((_ data: Data?) -> Void)? = nil) {
        let file = URL.cacheDirectory.appendingPathComponent(key, isDirectory: false)
        if !force, let data = try? Data(contentsOf: file) {
            dataCallback?(data)
            return
        }
        if let callback = dataCallback {
            callbacks[key] = callback
        }
        URLSession.dataSession.getAllTasks { (tasks) in
            guard !tasks.contains(where: { $0.originalRequest?.url == url }) else { return }
            URLSession.dataSession.dataTask(with: url) { [unowned self] (data, response, error) in
                try? data?.write(to: file)
                DispatchQueue.main.async {
                    self.callbacks[key]?(data)
                    self.callbacks.removeValue(forKey: key)
                }
            }.resume()
        }
    }

}
