//
//  QueueViewController.swift
//  
//
//  Created by Ali Siddiqui on 3/15/17.
//
//

import UIKit

class QueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: PartyViewControllerInfoDelegate?

    @IBOutlet weak var upNextLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var tracksTableView: UITableView!

    fileprivate var minHeight: CGFloat {
        return HubAndQueuePageViewController.minHeight
    }
    fileprivate var maxHeight: CGFloat {
        return HubAndQueuePageViewController.maxHeight
    }
    
    fileprivate var previousScrollOffset: CGFloat = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        adjustFontSizes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeFontSizeForUpNext()
    }
    
    private func adjustFontSizes() {
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            addButton.changeToSmallerFont()
            editButton.changeToSmallerFont()
        }
    }
    
    private func setDelegates() {
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Party.tracksQueue.count - 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Track In Queue") as! TrackTableViewCell
        
        if Party.tracksQueue.count > indexPath.row {
            cell.trackName.text = Party.tracksQueue[indexPath.row + 1].name
            cell.artistName.text = Party.tracksQueue[indexPath.row + 1].artist
            cell.artworkImageView.image = Party.tracksQueue[indexPath.row + 1].lowResArtwork
        }
        
        return cell
    }

    @IBAction func editCells(_ sender: UIButton) {
        if sender.titleLabel?.text == NSLocalizedString("Edit", comment: "") {
            tracksTableView.setEditing(true, animated: true)
            sender.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        } else {
            tracksTableView.setEditing(false, animated: true)
            sender.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return delegate!.isHost || delegate!.personalQueue.contains(where: { $0.id == Party.tracksQueue[indexPath.row + 1].id })
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return delegate!.isHost
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var newTracksQueue = Party.tracksQueue.map { $0.copy() } as! [Track]
        let itemMoved = newTracksQueue[sourceIndexPath.row + 1]
        
        newTracksQueue.remove(at: sourceIndexPath.row + 1)
        newTracksQueue.insert(itemMoved, at: destinationIndexPath.row + 1)
        
        Party.tracksQueue = newTracksQueue
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.reloadData()
            tableView.beginUpdates()
            let track = removeTrack(atIndex: indexPath.row + 1)
            tableView.deleteRows(at: [indexPath], with: .right)
            tableView.endUpdates()
            delegate?.sendTracksToPeers(forTracks: [track], toRemove: true)
        }
    }
    
    func removeTrack(atIndex index: Int) -> Track {
        return Party.tracksQueue.remove(at: index)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: NSLocalizedString("Remove", comment: "")) { (_, indexPath) in
            tableView.dataSource?.tableView?(
                tableView,
                commit: .delete,
                forRowAt: indexPath
            )
        }
        return [deleteButton]
    }
    
}

extension QueueViewController {
    
    private var headerHeightConstraint: CGFloat {
        get {
            return delegate?.tableHeight ?? maxHeight
        }
        
        set {
            delegate?.tableHeight = newValue
            if headerHeightConstraint == maxHeight {
                goIntoEditingMode()
            } else if headerHeightConstraint == minHeight {
                comeOutOfEditingMode()
            }
        }
    }
    
    // Code taken from https://michiganlabs.com/ios/development/2016/05/31/ios-animating-uitableview-header/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
        
        let absoluteTop: CGFloat = 0
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop && !Party.tracksQueue.isEmpty
        
        var newHeight = headerHeightConstraint
        
        if isScrollingDown {
            newHeight = max(maxHeight, headerHeightConstraint - abs(scrollDiff))
            if newHeight != headerHeightConstraint {
                headerHeightConstraint = newHeight
                changeFontSizeForUpNext()
                setScrollPosition(forOffset: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, headerHeightConstraint + abs(scrollDiff))
            if newHeight != headerHeightConstraint && tracksTableView.contentOffset.y < 2 {
                headerHeightConstraint = newHeight
                changeFontSizeForUpNext()
                setScrollPosition(forOffset: previousScrollOffset)
            }
        }
        
        previousScrollOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        makeTracksTableShorter()
    }
    
    fileprivate func changeFontSizeForUpNext() {
        UIView.animate(withDuration: 0.3) {
            self.upNextLabel.font = self.upNextLabel.font.withSize(20 - UILabel.smallerTitleFontSize * (self.headerHeightConstraint / self.minHeight))
        }
    }
    
    private func setScrollPosition(forOffset offset: CGFloat) {
        tracksTableView.contentOffset = CGPoint(x: tracksTableView.contentOffset.x, y: offset)
    }
    
    fileprivate func goIntoEditingMode() {
        if (delegate!.isHost && Party.tracksQueue.count > 1) || tracksQueueHasEditableTracks() {
            editButton.isHidden = false
            addButton.isHidden = true
        }
    }
    
    private func tracksQueueHasEditableTracks() -> Bool {
        for track in Party.tracksQueue {
            if delegate!.personalQueue.contains(where: { $0.id == track.id }) && track != Party.tracksQueue[0] {
                return true
            }
        }
        return false
    }
    
    fileprivate func comeOutOfEditingMode() {
        tracksTableView.setEditing(false, animated: true)
        editButton.isHidden = true
        addButton.isHidden = false
        editButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidStopScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidStopScrolling()
        }
    }
    
    func scrollViewDidStopScrolling() {
        let range = maxHeight - minHeight
        let midPoint = minHeight + (range / 2)
        
        delegate?.layout()
        if headerHeightConstraint > midPoint {
            makeTracksTableShorter()
            self.displayRatingsView()
        } else {
            makeTracksTableTaller()
        }
    }
    
    // MARK: - Party Control
    
    func updateTable() {
        DispatchQueue.main.async {
            if !self.tracksTableView.isEditing {
                self.tracksTableView.reloadData()
            }
        }
    }
    
    func showAddButton() {
        DispatchQueue.main.async {
            self.addButton.isHidden = false
            self.editButton.isHidden = true
            self.comeOutOfEditingMode()
            UIView.animate(withDuration: 0.3, animations: { self.addButton.alpha = 1 })
        }
    }
    
    func hideAddButton() {
        UIView.animate(withDuration: 0.3, animations: { self.addButton.alpha = 0 }) { _ in
            self.addButton.isHidden = true
        }
    }
    
    func makeTracksTableTaller() {
        DispatchQueue.main.async {
            self.delegate?.layout()
            UIView.animate(withDuration: 0.4) {
                self.headerHeightConstraint = self.maxHeight
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
            }
        }
    }
    
    func makeTracksTableShorter() {
        DispatchQueue.main.async {
            self.delegate?.layout()
            UIView.animate(withDuration: 0.4) {
                self.headerHeightConstraint = self.minHeight
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
            }
        }
    }
    
    func displayRatingsView() {
        if #available(iOS 10.3, *),
            UserDefaults.standard.integer(forKey: "launchCount") > AppConstants.minimumLaunchesBeforeReview &&
                !Party.tracksQueue.isEmpty &&
                delegate!.connectedUsers > 0 {
            SKStoreReviewController.requestReview()
        }
    }
    
}
