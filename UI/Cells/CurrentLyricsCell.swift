import UIKit
import Cartography

class CurrentLyricsCell: UICollectionViewCell {

    private lazy var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = .black
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        constrain(contentView, label) { (view, label) in
            label.edges == view.edges
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutSubviews()
        let fonts = [12, 14, 16].map { UIFont.systemFont(ofSize: $0) }
        let fitFont = fonts.reversed().first { $0.lineHeight * 2 <= label.bounds.size.height }
        label.font = fitFont ?? fonts.first
    }

    func setData(lyrics: [String]) {
        label.text = lyrics.joined(separator: "\n")
    }

}
