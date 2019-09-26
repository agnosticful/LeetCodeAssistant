import UIKit

class ProblemDetailTableViewController: UITableViewController {
    var problem: LeetCodeProblem!
    var problemDetail: LeetCodeProblemDetail!
    var isProblemDetailLoading = false
    var submissions: [LeetCodeSubmission]?
    var isSubmissionLoading = false
    var lastBestSubmission: LeetCodeSubmission?
    var isLastBestSubmission = false

    override func viewDidLoad() {
        super.viewDidLoad()

        isSubmissionLoading = true
        isProblemDetailLoading = true
        isLastBestSubmission = true
        tableView.reloadData()
        
        LeetCodeProblemRepository.shared.getProblemDetail(id: problem.id) { (problemDetail, error) in
            self.problemDetail = problemDetail
            
            DispatchQueue.main.async {
                self.isProblemDetailLoading = false
                self.tableView.reloadData()
            }
        }
        
        LeetCodeProblemRepository.shared.getAllSubmissions(of: problem!) { (submissions, error) in
            guard let submissions = submissions else {
                return
            }
            
            self.submissions = submissions
            self.lastBestSubmission = submissions.first { $0.status == .accepted } ?? submissions.first
            
            DispatchQueue.main.async {
                self.isSubmissionLoading = false
                self.isLastBestSubmission = false
                self.tableView.reloadData()
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if !isSubmissionLoading && submissions == nil {
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
            return 1
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
        case 2:
            if isSubmissionLoading {
                return nil
            }
            
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
            if isProblemDetailLoading {
                return tableView.dequeueReusableCell(withIdentifier: "LoadingCell")!
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell")! as! ProblemDetailTableViewDescriptionCell
            
            cell.set(problemDetail: problemDetail)
            
            return cell
        case (2, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "LastSubmissionCell")! as! ProblemDetailTableViewLastSubmissionCell
            
            cell.set(problem: problem)
            
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
    func set(problemDetail: LeetCodeProblemDetail) {
        textLabel?.text = problemDetail.content
    }
}

class ProblemDetailTableViewLastSubmissionCell: UITableViewCell {
    func set(problem: LeetCodeProblem) {
        textLabel?.text = "code"
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
