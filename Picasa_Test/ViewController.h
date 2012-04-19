//
//  ViewController.h
//  Picasa_Test
//
//  Created by Awais Munir on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GData.h"

@interface ViewController : UIViewController <UITextFieldDelegate>{
    UITextField *userNameTextField;
    UITextField *passTextField;
    NSError *mAlbumFetchError;
    NSError *mPhotosFetchError;
    
    GDataFeedPhotoUser *mUserAlbumFeed;
    GDataServiceTicket *mAlbumFetchTicket;
    GDataFeedPhotoAlbum *mAlbumPhotosFeed; // album feed of photo entries
    GDataServiceTicket *mPhotosFetchTicket;
    
    NSUserDefaults *usrDefaults;
}
@property (nonatomic, retain) IBOutlet UITextField *userNameTextField;
@property (nonatomic, retain) IBOutlet UITextField*passTextField;
-(IBAction)loginButtonAction:(id)sender;
-(IBAction)uploadPhotoAction:(id)sender;
-(IBAction)createAlbumAction:(id)sender;
@end
