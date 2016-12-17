//
//  MessagesController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-21.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD


class MessagesController: UIViewController, UITableViewDataSource, UITableViewDelegate, GameManagerObserver, ChatManagerObserver, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, HomeControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    let headerHeightOpen:CGFloat = 155
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    @IBOutlet weak var fakeMatches: UIImageView!
    @IBOutlet weak var backgroundTextLabel: UILabel!
    @IBOutlet weak var newMatchCountLabel: CustomLabel!
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var alertView: UIView!
    
    @IBOutlet weak var alertTitle: UILabel!
    
    @IBOutlet weak var alertBody: UILabel!
    
    var refreshControl:UIRefreshControl!
    
    var mode:MessageMode = .Blurvs
    
    var GamesOrigin:[Game] {
        
        return GameManager.sharedManager.games
    }
    var ChatOrigin:[Chat] {
        return ChatManager.sharedManager.chats
    }

    
    var games:[Game] = []
    var chats:[Chat] = []
    
    var newMatches:[Game] {
        return GameManager.sharedManager.newMatches
    }
    
    var loading:Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.hidden = true
        searchBar.delegate = self
        
        GameManager.sharedManager.addObserverForGameList(self)
        ChatManager.sharedManager.addObserverForChatList(self)
        
        games = GamesOrigin
        chats = ChatOrigin
        
        setupTableView()
        setupCollectionView()
        
        
    
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateNewMatches(animated)
        updateHeader(animated)
        
        updateBackgroundText()
        tableView.reloadData()
        collectionView.reloadData()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        clearSelection(animated)
    }
    @IBAction func hiddenAlert(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        if self.mode == .Chats {
            defaults.setObject("checked", forKey: "checkedChat")
        } else {
            defaults.setObject("checked", forKey: "checkedSession")
        }
        
        
        self.alertView.hidden = true
    }
    
    func homeControllerDidChangeMessageMode(newMode: MessageMode) {
        
        self.mode = newMode
        self.searchBar.text = ""
        self.searchBar.endEditing(true)
        self.searchBar.hidden = true
        if self.mode == .Chats {
            chats = ChatOrigin
            
        } else {
            
            games = GamesOrigin
           
        }
        tableView.reloadData()
        updateHeader(true)
        updateBackgroundText()
    }

    func updateHeader(animated:Bool) {
        let newHeight = mode == .Chats ? 0:headerHeightOpen
        headerHeightConstraint.constant = newHeight
        self.view.layoutIfNeeded()
    }
    
    func updateNewMatches(animated:Bool) {
        let hideCollectionView = (self.newMatches.count == 0)
        let animations = {
            self.collectionView.alpha = hideCollectionView ? 0:1
        }
        UIView.animateWithDuration(0.3) {
            animations()
        }
        self.newMatchCountLabel.text = String(self.newMatches.count)
        
    }
    
    func showAlertSession() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let checkedSession = defaults.stringForKey("checkedSession")
        if checkedSession == nil || checkedSession!.isEmpty {
            
            self.alertTitle.text = "All your matches are gathered here"
            self.alertBody.text = "Complete your sessions and then talk freely in the Chat room"
            self.alertView.hidden = false
        }
    }
    
    func showAlertChat() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let checkedChat = defaults.stringForKey("checkedChat")
        if checkedChat == nil || checkedChat!.isEmpty {
            
            self.alertTitle.text = "All your chats are gathered here"
            self.alertBody.text = "Talk freely in the Chat room"
            self.alertView.hidden = false
        }
    }
    
    func updateBackgroundText() {
        if mode == .Blurvs {
            self.alertView.hidden = true
            let message = NSLocalizedString("You don't have any sessions yet, we'll notify you when you do!", comment: "")
            self.backgroundTextLabel.text = message
            
            self.backgroundTextLabel.alpha = (self.newMatches.count + self.games.count) == 0 ? 1:0
            showAlertSession()
            
            let footerHeight:CGFloat = (self.newMatches.count + self.games.count) == 0 ? 200:0
            if let footer = tableView.tableFooterView {
                if footer.frame.height != footerHeight {
                    var newFrame = footer.frame
                    newFrame.size.height = footerHeight
                    footer.frame = newFrame
                    tableView.tableFooterView = footer
                }
            }
        }
        else {
            self.alertView.hidden = true
            let message = NSLocalizedString("What you talk about in here is none of our business, but keep it interesting!", comment: "")
            self.backgroundTextLabel.text = message
            
            self.backgroundTextLabel.alpha = (self.chats.count) == 0 ? 1:0
                showAlertChat()
            
            let footerHeight:CGFloat = (self.chats.count) == 0 ? 200:0
            if let footer = tableView.tableFooterView {
                if footer.frame.height != footerHeight {
                    var newFrame = footer.frame
                    newFrame.size.height = footerHeight
                    footer.frame = newFrame
                    tableView.tableFooterView = footer
                }
            }
        }
    }
    
    // MARK: TableView
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        setupRefreshControl()
    }
    
    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        refreshControl.addTarget(self, action: #selector(MessagesController.refresh), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
    }
    func refresh() {
        CATransaction.begin()
        CATransaction.setCompletionBlock { 
            self.tableView.reloadData()
            self.collectionView.reloadData()
        }
        refreshControl.endRefreshing()
        CATransaction.commit()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mode == .Blurvs {
            return self.games.count
        }
        else {
            return self.chats.count
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
        
        if mode == .Blurvs {
            let game = games[indexPath.row]
            let lastActivity = NSDate(timeIntervalSince1970: game.lastActivity)
            cell.timeLabel.text = lastActivity.timeAgo()
            cell.hasNotification = NotificationManager.sharedManager.notificationCountForGameWithId(game.id!) > 0
            cell.isFirst = indexPath.row == 0
            cell.nameLabel.text = game.otherUser!.firstName
            cell.descriptionLabel.text = game.statusDescription()
            cell.pictureView.pictureId = game.otherUser!.currentPictureIds.first
            cell.pictureView.blur = game.answerCountForQuestionAtIndex(0) != 2
            if cell.pictureView.blur {
                let lockedImage = UIImage(named: "image_lock")
                let lockedImageView = UIImageView(image: lockedImage)
                lockedImageView.frame = CGRect(x:0, y: 0, width: cell.pictureView.frame.width, height: cell.pictureView.frame.width)                
                cell.pictureView.addSubview(lockedImageView)
            }
            return cell
        }
        else {
            let chat = chats[indexPath.row]
            let lastActivity = chat.lastActivityDate()
            cell.timeLabel.text = lastActivity.timeAgo()
            cell.hasNotification = NotificationManager.sharedManager.notificationCountForChatWithId(chat.id) > 0
            cell.isFirst = indexPath.row == 0
            cell.nameLabel.text = chat.allOtherUsersName()
            cell.descriptionLabel.text = chat.info.lastMessage?.body ?? NSLocalizedString("No messages yet", comment: "")
            cell.pictureView.pictureId = chat.otherUsers()?.first?.currentPictureIds.first
            cell.pictureView.blur = false
            return cell
        }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20))
            view.backgroundColor = UIColor.clearColor()
            return view
        }
        return nil
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.mode == .Blurvs {
            self.searchBar.endEditing(true)
            let game = games[indexPath.row]
            let vc = storyboard!.instantiateViewControllerWithIdentifier("GameController") as! GameController
            vc.game = game
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let chat = chats[indexPath.row]
            let vc = storyboard!.instantiateViewControllerWithIdentifier("ChatController") as! ChatController
            vc.chat = chat
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    func clearSelection(animated:Bool) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
    
    // MARK: Collection View
    
    func setupCollectionView() {
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return newMatches.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("NewMatchCell", forIndexPath: indexPath) as! NewMatchCell
        let user = newMatches[indexPath.row].otherUser!
        cell.populateWithUser(user)
        return cell
    }
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let game = newMatches[indexPath.row]
        let vc = storyboard!.instantiateViewControllerWithIdentifier("GameController") as! GameController
        vc.game = game
        navigationController?.pushViewController(vc, animated: true)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 102, height: 112)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    
    
    // MARK: Game Manager Observer

    func gameDidChange(newGame: Game, atIndex index: Int) {
        if mode == .Blurvs {
            self.tableView.reloadData()
        }
    }
    func gameDidMove(newGame: Game, fromIndex oldIndex: Int, toIndex newIndex: Int) {
        if mode == .Blurvs {
            tableView.reloadData()
        }
    }
    func gameAdded(newGame: Game, atIndex index: Int) {
        print("added at index: \(index)")
        if mode == .Blurvs {
            games = GamesOrigin
            
            tableView.reloadData()
            
            
        }
        updateBackgroundText()
    }
    func gameRemoved(atIndex index: Int) {
        if mode == .Blurvs {
            tableView.reloadData()
        }
        updateBackgroundText()
    }
    func newMatchAdded(newMatch game: Game, atIndex index: Int) {
        if mode == .Blurvs {
            collectionView.reloadData()
        }
        updateNewMatches(mode == .Blurvs)
        updateBackgroundText()
    }
    func newMatchRemoved(atIndex index: Int) {
        if mode == .Blurvs {
            collectionView.reloadData()
        }
        updateNewMatches(mode == .Blurvs)
        updateBackgroundText()
    }
    
    // MARK: Chat Manager Observer
    func chatManagerDidAddNewChat(chat: Chat, atIndex index: Int) {
        if self.mode == .Chats {
            chats = ChatOrigin
            tableView.reloadData()
        }
        updateBackgroundText()
    }
    func chatManagerChatDidChange(newChat: Chat, atIndex index: Int) {
        if self.mode == .Chats {
            chats = ChatOrigin
            tableView.reloadData()
        }
        updateBackgroundText()
    }
    func chatManagerChatDidMove(newChat: Chat, fromIndex: Int, toIndex: Int) {
        if self.mode == .Chats {
            tableView.reloadData()
        }
        updateBackgroundText()
    }
    func chatManagerDidRemoveChat(atIndex index: Int) {
        if self.mode == .Chats {
            tableView.reloadData()
        }
        updateBackgroundText()
    }
    
    func onHideSearchBar() {
        searchBar.endEditing(true)
    }

    func onShowSearchBar() {
        if searchBar.hidden {
            searchBar.hidden = false
            searchBar.becomeFirstResponder()
            
        }else{
            searchBar.hidden = true
            searchBar.endEditing(true);
        }
        searchBar.text = ""
        FilterData()
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        NSLog("Cancel Button Clicked")
     //   FilterData()
    }
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        NSLog("TextDidEndEditing")
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        NSLog("seaarchBar button clicked")
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.becomeFirstResponder()
        NSLog("TextDidBeginEditing")
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        FilterData()
    }
    
    func FilterData(){
        let searchStr = searchBar.text! as String
        if self.mode == .Blurvs {
            games.removeAll()
            if searchStr == "" {
                games = GamesOrigin;
            }else{
                for vs in GamesOrigin{
                    var str = vs.otherUser?.firstName
                    str = str?.lowercaseString
                    if str!.rangeOfString(searchStr.lowercaseString) != nil {
                        games.append(vs)
                    }
                }
            }
        } else {
            chats.removeAll()
            if searchStr == "" {
                chats = ChatOrigin
            } else {
               // var i = 0
                for vs in ChatOrigin {
                    var str = vs.allOtherUsersName()//vs.users![i].firstName
                    str = str.lowercaseString
                    if str.rangeOfString(searchStr.lowercaseString) != nil {
                        chats.append(vs)
                    }
                    
                  //  i += 1
                }
            }
        }
        tableView.reloadData()
      //  updateBackgroundText()
    }

//    -(void)FilterData{
//    NSString *searchText = [_searchBar.text lowercaseString];
//    if ([filteredData count]) {
//    [filteredData removeAllObjects];
//    }
//    if ([searchText isEqualToString:@""]) {
//    filteredData = [arryScanDataList mutableCopy];
//    }else{
//    for (NSDictionary *oneData in arryScanDataList) {
//    NSString *Name = [oneData valueForKey:@"cName"];
//    Name = ([Name isEqual:[NSNull null]] || Name == nil) ? @"" : [Name lowercaseString];
//    
//    NSString *LastST = [oneData objectForKey:@"last_ScanTime"];
//    LastST = ([LastST isEqual:[NSNull null]] || LastST == nil) ? @"" : [LastST lowercaseString];
//    
//    NSString *Description = [oneData objectForKey:@"Description"];
//    Description = ([Description isEqual:[NSNull null]] || Description == nil) ? @"" : [Description lowercaseString];
//    
//    NSString *Age = [oneData objectForKey:@"age"];
//    Age = ([Age isEqual:[NSNull null]] || Age == nil) ? @"" : Age;
//    
//    if (([Name rangeOfString:searchText].location != NSNotFound) ||
//    ([LastST rangeOfString:searchText].location != NSNotFound) ||
//    ([Description rangeOfString:searchText].location != NSNotFound) ||
//    ([Age rangeOfString:searchText].location != NSNotFound)
//    ) {
//    [filteredData addObject:oneData];
//    }
//    }
//    }
//    [self.tblUsersList reloadData];
//    }

    
    
}
















