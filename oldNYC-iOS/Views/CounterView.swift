

import UIKit

class CounterView: UIView {
    
    let count: Int
    let countLabel = UILabel()
    var currentIndex: Int {
        didSet {
            updateLabel()
        }
    }
    
    init(frame: CGRect, currentIndex: Int, count: Int) {
        
        self.currentIndex = currentIndex
        self.count = count
        
        super.init(frame: frame)
        
        configureLabel()
        updateLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() {
        
        countLabel.textAlignment = .center
        self.addSubview(countLabel)
    }
    
    func updateLabel() {
        
        let stringTemplate = "%d of %d"
        let countString = String(format: stringTemplate, arguments: [currentIndex + 1, count])
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 17),
            .foregroundColor: UIColor.white
        ]
        countLabel.attributedText = NSAttributedString(string: countString, attributes: attributes)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        countLabel.frame = self.bounds
    }
}
