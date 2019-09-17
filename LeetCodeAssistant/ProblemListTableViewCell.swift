import UIKit

class ProblemListTableViewCell: UITableViewCell {
    @IBOutlet weak var problemNumberLabel: UILabel!
    @IBOutlet weak var problemTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setProblem(_ problem: LeetCodeProblem) {
        problemNumberLabel.text = "\(problem.number)."
        problemTitleLabel.text = problem.title
        
        switch problem.difficulty {
        case .easy:
            problemNumberLabel.textColor = .systemGreen
        case .medium:
            problemNumberLabel.textColor = .systemYellow
        case .hard:
            problemNumberLabel.textColor = .systemRed
        }
    }
}
