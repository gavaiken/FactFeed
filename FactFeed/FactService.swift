import UIKit
import reddift

struct FFSubredditURLPath: SubredditURLPath {
  let path: String;
}

struct Fact {
  let title: String;
}

class FactService: NSObject {
  let paginator = Paginator()

  func fetchFacts(completion: @escaping (Result<[Fact]>) -> Void) {
    do {
      let subreddit = FFSubredditURLPath(path: "r/todayilearned")
      try Session().getList(paginator, subreddit:subreddit, sort: .top, timeFilterWithin: .all) { (result) -> Void in
        switch result {
        case .failure(let error):
          print(error)
        case .success:
          if let children = result.value?.children {
            let links = children.flatMap { $0 as? Link }
            let facts = links.map({ (link) -> Fact in
              Fact(title: link.title)
            })
            completion(Result(value: facts))
          }
        }
      }
    } catch {
      completion(Result<[Fact]>(error: error as NSError))
    }
  }
}
