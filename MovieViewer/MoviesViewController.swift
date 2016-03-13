//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Weifan Lin on 2/5/16.
//  Copyright © 2016 Weifan Lin. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD
//import SystemConfiguration

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var errMsgButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var endpoint : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
//        tableView.addSubview(errMsgButton)
        
        if Reachability.isConnectedToNetwork() {
            errMsgButton.hidden = true
//            errMsgButton.removeFromSuperview()
            MBProgressHUD.showHUDAddedTo(self.view, animated: true)// show loading state
            loadDataFromNetwork()
            MBProgressHUD.hideHUDForView(self.view, animated: true)// hide loading state
        } else {
            errMsgButton.hidden = false
        }
        
        
        // Do any additional setup after loading the view.
        
//        searchBarTextDidBeginEditing(searchBar: UISearchBar)
//        
//        searchBarCancelButtonClicked(searchBar: UISearchBar)
//        
//        func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//            self.searchBar.showsCancelButton = true
//        }
//        
//        func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//            searchBar.showsCancelButton = false
//            searchBar.text = ""
//            searchBar.resignFirstResponder()
//        }
        
    }
    
    internal class Reachability {
        class func isConnectedToNetwork() -> Bool {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
                SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
            }
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
                return false
            }
            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            return (isReachable && !needsConnection)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadDataFromNetwork() {
        
        // Create the NSURLRequest
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        // show loading state
        //
    
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                //hide loading state
                //
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            //print("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.tableView.reloadData()
                    }
                }
        })
        task.resume()
    }
    
    @IBAction func errMsgTap(sender: AnyObject) {
        if Reachability.isConnectedToNetwork() {
            errMsgButton.hidden = true
            MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            loadDataFromNetwork()
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        } else {
            errMsgButton.hidden = false
        }
    }

    func refreshControlAction(refreshControl: UIRefreshControl) {
        
        if Reachability.isConnectedToNetwork() {
            errMsgButton.hidden = true
        } else {
            errMsgButton.hidden = false
            refreshControl.endRefreshing()
        }
        
        loadDataFromNetwork()
        refreshControl.endRefreshing()
    
    }
    

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredData = filteredData {
            return filteredData.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        

        let movie = filteredData![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        
        if let posterPath = movie["poster_path"] as? String {
            //Encountered a movie with nil poster_path!
            
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        } else {
            cell.posterView.image = nil 
        }

        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        return cell
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = self.movies
        if searchText.isEmpty {
            tableView.reloadData()
        }
        else {
            var searchDic = [NSDictionary]()
            for each in filteredData! {
                let titleString = each["title"] as? String
                if titleString!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil {
                    searchDic.append(each)
                }
                
                filteredData = searchDic
            }
            tableView.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredData = movies
        tableView.reloadData()
    }
        
        
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
    }


}
