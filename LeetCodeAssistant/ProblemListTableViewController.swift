import UIKit

class ProblemListTableViewController: UITableViewController, UISearchBarDelegate {
    var solvedProblems = [UserLeetCodeProblem]()
    var attemptedProblems = [UserLeetCodeProblem]()
    var unsolvedProblems = [UserLeetCodeProblem]()
    var filteredSolvedProblems = [UserLeetCodeProblem]()
    var filteredAttemptedProblems = [UserLeetCodeProblem]()
    var filteredUnsolvedProblems = [UserLeetCodeProblem]()
    var areProblemsLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchController = UISearchController()

        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search Problems"
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        
        areProblemsLoading = true

        LeetCodeProblemRepository.shared.getAllProblems { (problems, error) in
            guard let problems = problems else {
                return
            }
            
            DispatchQueue.main.async {
                self.solvedProblems = problems.filter({ $0.status == .solved }).sorted { $0.problem.number < $1.problem.number }
                self.attemptedProblems = problems.filter({ $0.status == .attempted }).sorted { $0.problem.number < $1.problem.number }
                self.unsolvedProblems = problems.filter({ $0.status == .unsolved }).sorted { $0.problem.number < $1.problem.number }
                self.filteredSolvedProblems = self.solvedProblems
                self.filteredAttemptedProblems = self.attemptedProblems
                self.filteredUnsolvedProblems = self.unsolvedProblems
                self.areProblemsLoading = false
                
                self.tableView.reloadData()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "GoToDetail" else {
            return
        }

        let problemDetailTVC = segue.destination as! ProblemDetailTableViewController
        let indexPath = tableView.indexPathForSelectedRow!
        
        switch indexPath.section {
        case 0:
            problemDetailTVC.problem = filteredSolvedProblems[indexPath.row].problem
        case 1:
            problemDetailTVC.problem = filteredAttemptedProblems[indexPath.row].problem
        case 2:
            problemDetailTVC.problem = filteredUnsolvedProblems[indexPath.row].problem
        default:
            assertionFailure("must not reach here")
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if areProblemsLoading {
            return 1
        }

        if section == 0 {
            return filteredSolvedProblems.count
        }

        if section == 1 {
            return filteredAttemptedProblems.count
        }

        if section == 2 {
            return filteredUnsolvedProblems.count
        }

        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Solved (\(filteredSolvedProblems.count))"
        }

        if section == 1 {
            return "Attempted (\(filteredAttemptedProblems.count))"
        }

        if section == 2 {
            return "Unsolved (\(filteredUnsolvedProblems.count))"
        }

        return ""
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if areProblemsLoading {
            return tableView.dequeueReusableCell(withIdentifier: "ProblemListTableViewLoadingCell")!
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProblemListTableViewCell") as! ProblemListTableViewCell

        if indexPath.section == 0 {
            cell.setProblem(filteredSolvedProblems[indexPath.row].problem)
        } else if indexPath.section == 1 {
            cell.setProblem(filteredAttemptedProblems[indexPath.row].problem)
        } else if indexPath.section == 2 {
            cell.setProblem(filteredUnsolvedProblems[indexPath.row].problem)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text?.trimmingCharacters(in: .whitespaces) {
            if let number = Int(text) {
                filteredSolvedProblems = solvedProblems.filter { String($0.problem.number).contains(String(number)) }
                filteredAttemptedProblems = attemptedProblems.filter { String($0.problem.number).contains(String(number)) }
                filteredUnsolvedProblems = unsolvedProblems.filter { String($0.problem.number).contains(String(number)) }
            } else {
                filteredSolvedProblems = solvedProblems.filter { $0.problem.title.contains(text) }
                filteredAttemptedProblems = attemptedProblems.filter { $0.problem.title.contains(text) }
                filteredUnsolvedProblems = unsolvedProblems.filter { $0.problem.title.contains(text) }
            }

            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredSolvedProblems = solvedProblems
        filteredAttemptedProblems = attemptedProblems
        filteredUnsolvedProblems = unsolvedProblems
        
        tableView.reloadData()
    }

    @IBAction func onAccountButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (UIAlertAction) in
            LeetCodeProblemRepository.shared.signOut()
            LeetCodeSessionStorage.shared.delete()
            
            self.performSegue(withIdentifier: "SignOut", sender: self)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}
