import UIKit
import reddift

struct FFSubredditURLPath: SubredditURLPath {
  let path: String;
}

struct Fact {
  let title: String;
}

class FactService: NSObject {
  let subreddit = FFSubredditURLPath(path: "r/todayilearned")
  var paginator: Paginator? = Paginator()

  func fetchNextFacts(completion: @escaping (Result<[Fact]>) -> Void) {
    guard let paginator = paginator else {
      completion(Result<[Fact]>(error: nil))
      return
    }

    do {
      try Session().getList(paginator, subreddit:subreddit, sort: .top, timeFilterWithin: .all) { (result) -> Void in
        switch result {
        case .failure(let error):
          print(error)
        case .success:
          if let value = result.value {
            self.paginator = FactService.getNextPaginator(paginator: value.paginator)
            let links = value.children.flatMap { $0 as? Link }
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
  
  class func getNextPaginator(paginator: Paginator?) -> Paginator? {
    if let prevPaginator = paginator {
      let dict = prevPaginator.parameterDictionary
      if let before = dict["before"] {
        // Set the 'before' parameter
        let nextPaginator = Paginator(after: "", before: before, modhash: "")
        return nextPaginator
      } else {
        // The current page did not come 'before' another page we can fetch.
        return nil;
      }
    } else {
      // First fetch.
      return Paginator()
    }
  }
}
