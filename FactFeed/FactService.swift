import UIKit
import reddift

struct FFSubredditURLPath: SubredditURLPath {
  let path: String
}

struct Fact {
  let title: String
}

class FactService {
  fileprivate let subreddit = FFSubredditURLPath(path: "r/todayilearned")
  fileprivate var paginator: Paginator? = Paginator()

  func fetchNextFacts(completion: @escaping (Result<[Fact]>) -> Void) {
    guard let paginator = paginator else {
      completion(Result<[Fact]>(error: nil))
      return
    }

    do {
      try Session().getList(paginator, subreddit:subreddit, sort: .top, timeFilterWithin: .all) { [weak self] (result) -> Void in
        self?.process(result: result, completion: completion)
      }
    } catch {
      completion(Result<[Fact]>(error: error as NSError))
    }
  }
  
  private func process(result: Result<Listing>, completion: @escaping (Result<[Fact]>) -> Void) {
    switch result {
    case .failure(let error):
      completion(Result<[Fact]>(error: error as NSError))
    case .success:
      if let value = result.value {
        self.paginator = FactService.paginator(after: value.paginator)
        let links = value.children.flatMap { $0 as? Link }
        let facts = links.map({ (link) -> Fact in
          Fact(title: link.title)
        })
        completion(Result(value: facts))
      } else {
        completion(Result(error: nil))
      }
    }
  }
  
  private class func paginator(after paginator: Paginator?) -> Paginator? {
    guard let paginator = paginator else {
      // First fetch.
      return Paginator()
    }

    guard let after = paginator.parameterDictionary["after"] else {
      // There is no page 'after' this one.
      return nil
    }

    let nextPaginator = Paginator(after: after, before: "", modhash: "")
    return nextPaginator
  }
}
