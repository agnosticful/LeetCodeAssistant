import UIKit

class ProblemDetailTableViewController: UITableViewController {
    @IBOutlet weak var problemTitleLabel: UILabel!
    @IBOutlet weak var problemNumberLabel: UILabel!
    @IBOutlet weak var problemDifficultyLabel: UILabel!
    @IBOutlet weak var problemDescriptionLabel: UILabel!
    @IBOutlet weak var problemLastSubmittedCodeLabel: UILabel!
    @IBOutlet weak var problemLastSubmissionStatusLabel: UILabel!
    @IBOutlet weak var staticFirstTableViewCell: UITableViewCell!
    
    var problem: LeetCodeProblem?
    var lastSubmission: LeetCodeSubmission?
    var isLastSubmissionLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        staticFirstTableViewCell?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)

        updateView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "Written in JavaScript. Took 52ms and 35.5MB RAM to finish."
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return problemNumberLabel.frame.height
        case (0, 1):
            return problemTitleLabel.frame.height
        case (1, 0):
            return problemDescriptionLabel.frame.height
        case (2, 0):
            return problemLastSubmittedCodeLabel.frame.height
        default:
            return UITableView.automaticDimension
        }
    }

    func updateView() {
        guard let problem = problem else {
            assertionFailure("problem always must not be nil")

            return
        }
        
        tableView.beginUpdates()

        problemNumberLabel.text = "No. \(problem.number)"
        problemTitleLabel.text = problem.title
        problemDescriptionLabel.text = ""

        switch problem.difficulty {
        case .easy:
            problemDifficultyLabel.text = "Easy"
            problemDifficultyLabel.textColor = .systemGreen
        case .medium:
            problemDifficultyLabel.text = "Medium"
            problemDifficultyLabel.textColor = .systemYellow
        case .hard:
            problemDifficultyLabel.text = "Hard"
            problemDifficultyLabel.textColor = .systemRed
        }

        if isLastSubmissionLoading {
            problemLastSubmittedCodeLabel.text = "Loading..."
            problemLastSubmittedCodeLabel.textColor = .secondaryLabel
            problemLastSubmissionStatusLabel.text = "Loading..."
            problemLastSubmissionStatusLabel.textColor = .secondaryLabel
        } else {
            if let lastSubmission = lastSubmission {
                problemLastSubmittedCodeLabel.text = lastSubmission.code
                problemLastSubmittedCodeLabel.textColor = .label

                switch lastSubmission.status {
                case .accepted:
                    problemLastSubmissionStatusLabel.text = "Accepted"
                    problemLastSubmissionStatusLabel.textColor = .systemGreen
                case .failed:
                    problemLastSubmissionStatusLabel.text = "Failed"
                    problemLastSubmissionStatusLabel.textColor = .systemRed
                }
            } else {
                problemLastSubmittedCodeLabel.text = ""
                problemLastSubmissionStatusLabel.text = ""
            }
        }
        
        tableView.endUpdates()
    }
}
