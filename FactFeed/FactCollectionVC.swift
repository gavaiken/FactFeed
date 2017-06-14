import UIKit
import EZAlertController

final class FactCollectionVC: UICollectionViewController {
  fileprivate let reuseIdentifier = "FactCell"
  fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  fileprivate let itemsPerRow: CGFloat = 1
  
  fileprivate let factService = FactService()
  fileprivate let nlpService = NLPService()
  fileprivate var facts = [Fact]()
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.collectionView!.addInfiniteScrolling { [weak self] in
      self?.loadMoreData {
        // Must be called for subsequent infinite scroll attempts to succeed.
        self?.collectionView?.infiniteScrollingView.stopAnimating()
      }
    }
    
    self.collectionView!.triggerInfiniteScrolling()
  }
  
  private func loadMoreData(completion: @escaping () -> Void) {
    factService.fetchNextFacts { (result) in
      switch result {
      case .failure(let error):
        EZAlertController.alert("Failed", message: "Error : \(error)")
      case .success:
        if let facts = result.value {
          self.facts += facts
          print("Fetched \(facts.count) facts, \(self.facts.count) total")
          DispatchQueue.main.async(execute: { [weak self] () -> () in
            self?.collectionView?.reloadData()
            completion()
          });
          return;
        }
      }
      completion()
    }
  }
}

// MARK: UICollectionViewDataSource
extension FactCollectionVC {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return self.facts.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                  for: indexPath) as! FactCVCell
    let fact = facts[indexPath.row]
    cell.label.text = fact.title
    
    return cell
  }
}

extension FactCollectionVC : UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    let heightPerItem = floor(widthPerItem * 0.6)
    
    return CGSize(width: widthPerItem, height: heightPerItem)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
