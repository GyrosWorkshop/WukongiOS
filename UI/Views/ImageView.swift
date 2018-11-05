import UIKit

class ImageView: UIImageView {

    private var imageKey: String? = nil
    private var imageURL: URL? = nil

    func setImage(key: String? = nil, url: URL? = nil, placeholder: UIImage? = nil) {
        guard imageKey != key || imageURL != url else { return }
        imageKey = key
        imageURL = url
        image = placeholder
        let callback = { [weak self] (data: Data?) in
            guard let data = data else { return }
            self?.image = UIImage(data: data)
        }
        guard let url = url else { return }
        if let key = key {
            DataLoader.sharedInstance.load(key: key, url: url, callback)
        } else {
            DataLoader.sharedInstance.load(url: url, callback)
        }
    }

}
