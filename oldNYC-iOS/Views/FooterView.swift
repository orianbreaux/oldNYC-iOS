import UIKit

class FooterView: UIView {
    
    let count: Int
    var yearLabel: UITextView? = UITextView()
    var attributedLabelText: NSMutableAttributedString = NSMutableAttributedString()
    var gradientLayer: CAGradientLayer = CAGradientLayer()
    var year: String{
        didSet {
//            updateYear()
        }
    }
    var summary: String{
        didSet {
            updateSummary()
        }
    }
    
    init(frame: CGRect, year: String, summary:String, count: Int) {
        self.year = year
        self.summary = summary
        self.count = count
        
        super.init(frame: frame)
        
        setupTextView()
        updateGradient()
        configureLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLabel() {
        yearLabel!.textAlignment = .left
    }
    
    func updateSummary() {
        var smallSummary = ""
        var attributes: [NSAttributedString.Key: Any]
        
        if self.frame.height != 100.0 {
            attributedLabelText = NSMutableAttributedString(string: "\n", attributes: nil)
            
            attributes = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.white
            ]
            attributedLabelText.append(NSAttributedString(string: year, attributes: attributes))
            
            attributedLabelText.append(NSAttributedString(string: "\n", attributes: nil))
            
            attributes = [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.white
            ]
            attributedLabelText.append(NSAttributedString(string: summary, attributes: attributes))
        } else {
            if !summary.isEmpty {
                attributedLabelText = NSMutableAttributedString(string: "\n", attributes: nil)
                
                attributes = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.white
                ]
                attributedLabelText.append(NSAttributedString(string: year, attributes: attributes))
                
                attributedLabelText.append(NSAttributedString(string: "\n", attributes: nil))
                
                if summary.count > 29 {
                    smallSummary = String(summary[..<summary.index(summary.startIndex, offsetBy: 30)])
                    if smallSummary.components(separatedBy: "\n").count > 1{
                        smallSummary = smallSummary.components(separatedBy: "\n")[0] + smallSummary.components(separatedBy: "\n")[1]
                    }
                    
                    attributes = [
                        .font: UIFont.systemFont(ofSize: 15),
                        .foregroundColor: UIColor.white
                    ]
                    attributedLabelText.append(NSAttributedString(string: smallSummary, attributes: attributes))
                    
                    attributes = [
                        .font: UIFont.systemFont(ofSize: 15),
                        .foregroundColor: UIColor.gray
                    ]
                    attributedLabelText.append(NSAttributedString(string: "... See More", attributes: attributes))
                    
                    if smallSummary.components(separatedBy: "\n").count == 1 {
                        attributedLabelText.append(NSAttributedString(string: "\n", attributes: attributes))
                    } else if smallSummary.components(separatedBy: "\n").count == 0 {
                        attributedLabelText.append(NSAttributedString(string: "\n\n", attributes: attributes))
                    }
                } else {
                    smallSummary = summary
                    attributes = [
                        .font: UIFont.systemFont(ofSize: 15),
                        .foregroundColor: UIColor.white
                    ]
                    attributedLabelText.append(NSAttributedString(string: smallSummary, attributes: attributes))
                }
            } else {
                attributedLabelText = NSMutableAttributedString(string: "\n\n\n", attributes: nil)
                
                attributes = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.white
                ]
                attributedLabelText.append(NSAttributedString(string: year, attributes: attributes))
            }
        }
        updateCredit()
    }
    
    func updateCredit() {
        attributedLabelText.append(NSAttributedString(string: "\n", attributes: nil))
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.gray
        ]
        attributedLabelText.append(NSAttributedString(string: "NYPL Irma and Paul Milstein Collection", attributes: attributes))
        
        yearLabel?.attributedText = attributedLabelText
    }
    
    func updateGradient() {
        yearLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    func setupTextView() {
        yearLabel = UITextView(frame: CGRect.zero, textContainer: nil)
        yearLabel?.translatesAutoresizingMaskIntoConstraints = false
        yearLabel?.isEditable = false
        yearLabel?.isScrollEnabled = true
        yearLabel?.dataDetectorTypes = UIDataDetectorTypes()
        yearLabel?.backgroundColor = UIColor.clear
        yearLabel?.textContainerInset = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 0.0, right: 2.0)
        self.addSubview(yearLabel!)
        let topConstraint: NSLayoutConstraint = NSLayoutConstraint(item: yearLabel!, attribute: .top, relatedBy: .equal, toItem: yearLabel!, attribute: .top, multiplier: 1.0, constant: 0.0)
        let bottomConstraint: NSLayoutConstraint = NSLayoutConstraint(item: yearLabel!, attribute: .bottom, relatedBy: .equal, toItem: yearLabel!, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        let widthConstraint: NSLayoutConstraint = NSLayoutConstraint(item: yearLabel!, attribute: .width, relatedBy: .equal, toItem: yearLabel!, attribute: .width, multiplier: 1.0, constant: 0.0)
        let horizontalPositionConstraint: NSLayoutConstraint = NSLayoutConstraint(item: yearLabel!, attribute: .centerX, relatedBy: .equal, toItem: yearLabel!, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        yearLabel!.addConstraints([topConstraint, bottomConstraint, widthConstraint, horizontalPositionConstraint])
        yearLabel?.autocorrectionType = UITextAutocorrectionType.no
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        yearLabel!.frame = self.bounds
        yearLabel!.setContentOffset(CGPoint.zero, animated: false)
        yearLabel!.contentOffset.x = 0.0
        yearLabel!.contentOffset.y = 0.0
    }
}
