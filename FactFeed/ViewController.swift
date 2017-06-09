import UIKit
import reddift

class ViewController: UIViewController {

  override func viewDidAppear(_ animated: Bool) {
    do {
      try Session().getList(Paginator(), subreddit: nil, sort: .controversial, timeFilterWithin: .week) { (result) -> Void in
        switch result {
        case .failure(let error):
          print(error)
        case .success:
          print("Success")
        }
      }
    } catch {
    }
  }

  @IBAction func didTapLogin(_ sender: UIButton) {
    do {
      try OAuth2Authorizer.sharedInstance.challengeWithAllScopes()
    } catch {
    }
  }
}

