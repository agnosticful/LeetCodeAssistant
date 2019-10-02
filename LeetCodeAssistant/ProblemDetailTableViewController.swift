import UIKit

class ProblemDetailTableViewController: UITableViewController {
    var problem: LeetCodeProblem!
    private var problemDescription: LeetCodeProblemDescription?
    private var isproblemDescriptionLoading = false
    private var submissions: [LeetCodeSubmission]?
    private var isSubmissionLoading = false
    private var lastBestSubmission: LeetCodeSubmission?
    private var lastBestSubmissionCode: String?
    private var isLastBestSubmissionCodeLoading = false
    private var isNoSubmission: Bool {
        get { return !isSubmissionLoading && lastBestSubmission == nil }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isSubmissionLoading = true
        isproblemDescriptionLoading = true
        isLastBestSubmissionCodeLoading = true

        tableView.reloadData()
        
        LeetCodeProblemRepository.shared.getProblemDescription(id: problem.id) { (problemDescription, error) in
            self.isproblemDescriptionLoading = false

            guard let problemDescription = problemDescription else { return }

            self.problemDescription = problemDescription

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        LeetCodeProblemRepository.shared.getAllSubmissions(of: problem!) { (submissions, error) in
            self.isSubmissionLoading = false

            guard let submissions = submissions else {
                self.tableView.reloadData()
                
                return
            }
            
            self.submissions = submissions
            self.lastBestSubmission = submissions.first { $0.status == .accepted } ?? submissions.first
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            if let submission = self.lastBestSubmission {
                LeetCodeProblemRepository.shared.getSubmittedCode(of: submission) { (code, error) in
                    self.lastBestSubmissionCode = code
                    self.isLastBestSubmissionCodeLoading = false
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isNoSubmission {
            return 2
        }

        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return isNoSubmission ? 0 : 1
        case 3:
            if isSubmissionLoading {
                return 1
            }
            
            if let submissions = submissions {
                return submissions.count
            }
            
            return 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Description"
        case 2:
            return "Your Code"
        case 3:
            if let submissions = submissions {
                return "Your Submissions (\(submissions.count))"
            }
            
            return "Your Submissions"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return isNoSubmission ? "You've never submitted to this problem." : nil
        case 2:
            if let submission = lastBestSubmission {
                return "Written in \(submission.usedLanguage). Took \(submission.runtime) and \(submission.memoryUsage) RAM to finish."
            }
            
            return nil
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MetaCell")! as! ProblemDetailTableViewMetaCell
            
            if isSubmissionLoading {
                cell.setLoading(problem: problem)
            } else {
                cell.set(problem: problem, submission: lastBestSubmission)
            }

            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            
            return cell
        case (0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell")! as! ProblemDetailTableViewTitleCell
            
            cell.set(problem: problem)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            
            return cell
        case (1, 0):
            if isproblemDescriptionLoading {
                return tableView.dequeueReusableCell(withIdentifier: "LoadingCell")!
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell")! as! ProblemDetailTableViewDescriptionCell
            
            if let problemDescription = problemDescription {
                cell.set(problemDescription: problemDescription)
            } else {
                cell.setFailed()
            }

            return cell
        case (2, 0):
            if isLastBestSubmissionCodeLoading {
                return tableView.dequeueReusableCell(withIdentifier: "LoadingCell")!
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "LastSubmissionCell")! as! ProblemDetailTableViewLastSubmissionCell
            
            cell.set(problem: problem, code: lastBestSubmissionCode)
            
            return cell
        case (3, _):
            if isSubmissionLoading {
                return tableView.dequeueReusableCell(withIdentifier: "LoadingCell")!
            }
            
            guard let submissions = submissions else {
                return tableView.dequeueReusableCell(withIdentifier: "LoadingCell")!
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubmissionCell")! as! ProblemDetailTableViewSubmissionCell
            
            cell.set(submission: submissions[indexPath.row])
            
            return cell
        default:
            assertionFailure()

            return UITableViewCell()
        }
    }
}

class ProblemDetailTableViewMetaCell: UITableViewCell {
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var lastSubmissionStatusLabel: UILabel!

    func setLoading(problem: LeetCodeProblem) {
        numberLabel.text = "No. \(problem.number)"

        switch problem.difficulty {
        case .easy:
            difficultyLabel.text = "Easy"
            difficultyLabel.textColor = .systemGreen
        case .medium:
            difficultyLabel.text = "Medium"
            difficultyLabel.textColor = .systemYellow
        case .hard:
            difficultyLabel.text = "Hard"
            difficultyLabel.textColor = .systemRed
        }

        lastSubmissionStatusLabel.text = "Loading..."
        lastSubmissionStatusLabel.textColor = .secondarySystemFill
    }
    
    func set(problem: LeetCodeProblem, submission: LeetCodeSubmission?) {
        numberLabel.text = "No. \(problem.number)"

        switch problem.difficulty {
        case .easy:
            difficultyLabel.text = "Easy"
            difficultyLabel.textColor = .systemGreen
        case .medium:
            difficultyLabel.text = "Medium"
            difficultyLabel.textColor = .systemYellow
        case .hard:
            difficultyLabel.text = "Hard"
            difficultyLabel.textColor = .systemRed
        }
        
        if let submission = submission {
            switch submission.status {
            case .accepted:
                lastSubmissionStatusLabel.text = "Accepted"
                lastSubmissionStatusLabel.textColor = .systemGreen
            case .failed:
                lastSubmissionStatusLabel.text = "Failed"
                lastSubmissionStatusLabel.textColor = .systemRed
            }
        } else {
            lastSubmissionStatusLabel.text = ""
        }
    }
}

class ProblemDetailTableViewTitleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    func set(problem: LeetCodeProblem) {
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        titleLabel.text = problem.title
    }
}

class ProblemDetailTableViewDescriptionCell: UITableViewCell {
    func set(problemDescription: LeetCodeProblemDescription) {
        textLabel?.text = problemDescription
    }
    
    func setFailed() {
        textLabel?.text = "Failed to load description."
    }
}

class ProblemDetailTableViewLastSubmissionCell: UITableViewCell {
    func set(problem: LeetCodeProblem, code: String?) {
        guard let code = code else { return }
        
        textLabel?.text = code
    }
}

class ProblemDetailTableViewSubmissionCell: UITableViewCell {
    func set(submission: LeetCodeSubmission) {
        

        switch submission.status {
        case .accepted:
            textLabel?.text = "Accepted"
            textLabel?.textColor = .systemGreen
        case .failed:
            textLabel?.text = "Failed"
            textLabel?.textColor = .systemRed
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true

        detailTextLabel?.text = "\(submission.usedLanguage) • \(submission.runtime) • \(submission.memoryUsage) • \(dateFormatter.string(from: submission.submittedAt))"
    }
}
