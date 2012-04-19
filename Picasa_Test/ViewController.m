//
//  ViewController.m
//  Picasa_Test
//
//  Created by Awais Munir on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "GData.h"
@interface ViewController (){
    
}
- (void)fetchAllAlbums; 
- (void)setAlbumFeed:(GDataFeedPhotoUser *)feed;
- (void)setAlbumFetchError:(NSError *)error;
- (void)setAlbumFetchTicket:(GDataServiceTicket *)ticket;
- (void)setPhotoFeed:(GDataFeedPhotoAlbum *)feed;
- (void)setPhotoFetchError:(NSError *)error;
- (void)setPhotoFetchTicket:(GDataServiceTicket *)ticket;
- (GDataFeedPhotoUser *)albumFeed;
- (GDataFeedPhotoAlbum *)photoFeed;
- (GDataServiceGooglePhotos *)googlePhotosService;
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error;
@end

@implementation ViewController
@synthesize userNameTextField, passTextField;
- (void)viewDidLoad
{
    [super viewDidLoad];
    usrDefaults  = [NSUserDefaults standardUserDefaults];
    if([usrDefaults stringForKey:@"UserName"]){
        userNameTextField.text = [usrDefaults stringForKey:@"UserName"];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
#pragma mark -
#pragma mark Actions
-(IBAction)loginButtonAction:(id)sender{
    NSLog(@"@@@ Going to Sign-In");
    [usrDefaults setValue:userNameTextField.text forKey:@"UserName"];
    [usrDefaults synchronize];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *username = [userNameTextField text];
    username = [username stringByTrimmingCharactersInSet:whitespace];
    
    if ([username rangeOfString:@"@"].location == NSNotFound) {
        // if no domain was supplied, add @gmail.com
        username = [username stringByAppendingString:@"@gmail.com"];
    }
    [userNameTextField setText:username];
    [self fetchAllAlbums];

}
-(IBAction)fetchSpecificAlbum:(id)sender{
     [self fetchSelectedAlbum];
}
-(IBAction)uploadPhotoAction:(id)sender{
    
   
    GDataFeedPhotoAlbum *albumFeedOfPhotos = [self photoFeed];
    NSURL *uploadURL = [[[albumFeedOfPhotos uploadLink] URL] retain];
    NSString *photoPath = [[NSBundle mainBundle] pathForResource:@"Fisker_auto" ofType:@"jpg"];
    NSString *photoName = [photoPath lastPathComponent];
    
    NSData *photoData = [NSData dataWithContentsOfFile:photoPath];
    if (photoData) {
        GDataEntryPhoto *newEntry = [GDataEntryPhoto photoEntry];
        [newEntry setTitleWithString:photoName];
        [newEntry setPhotoDescriptionWithString:photoPath];
        [newEntry setTimestamp:[GDataPhotoTimestamp timestampWithDate:[NSDate date]]];
        [newEntry setPhotoData:photoData];
        NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:photoPath
                                                   defaultMIMEType:@"image/jpeg"];
        [newEntry setPhotoMIMEType:mimeType];
        [newEntry setUploadSlug:photoName];
        GDataServiceGooglePhotos *service = [self googlePhotosService];
        SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
        [service setServiceUploadProgressSelector:progressSel];
        GDataServiceTicket *ticket;
        ticket = [service fetchEntryByInsertingEntry:newEntry
                                          forFeedURL:uploadURL
                                            delegate:self
                                   didFinishSelector:@selector(addPhotoTicket:finishedWithEntry:error:)];
        [service setServiceUploadProgressSelector:nil];
    }else {
        NSLog(@"@@@ Image not loaded");
    }
    

}

- (void)ticket:(GDataServiceTicket *)ticket
hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
ofTotalByteCount:(unsigned long long)dataLength {
    
//    [mUploadProgressIndicator setMinValue:0.0];
//    [mUploadProgressIndicator setMaxValue:(double)dataLength];
//    [mUploadProgressIndicator setDoubleValue:(double)numberOfBytesRead];
    int max = (int)dataLength;
    int current = (int) numberOfBytesRead;
    int percentage = (100*current)/max;
    NSLog(@"Uploading... %d%%",percentage );
    
}
- (void)addPhotoTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntryPhoto *)photoEntry
                 error:(NSError *)error {
    
    if (error == nil) {
        NSLog(@"@@@ Successfully Uploaded");
    }else {
        NSLog(@"@@@ ERROR ");
    }
}



////// Create Album
-(IBAction)createAlbumAction:(id)sender{
    
    NSString *albumName = @"New-Album";
        
    NSString *description = [NSString stringWithFormat:@"Created %@",
                             [NSDate date]];
    
    GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
    [newAlbum setTitleWithString:albumName];
    [newAlbum setPhotoDescriptionWithString:description];
    [newAlbum setAccess:kGDataPhotoAccessPrivate];
    
    NSURL *postLink = [[mUserAlbumFeed postLink] URL];
    GDataServiceGooglePhotos *service = [self googlePhotosService];
    
    [service fetchEntryByInsertingEntry:newAlbum
                             forFeedURL:postLink
                               delegate:self
                      didFinishSelector:@selector(createAlbumTicket:finishedWithEntry:error:)];
}
- (void)createAlbumTicket:(GDataServiceTicket *)ticket
        finishedWithEntry:(GDataEntryPhotoAlbum *)entry
                    error:(NSError *)error {
    if (error == nil) {
        NSLog(@"=======Successfully Created =========");
     } else {
         NSLog(@"==========ERROR===========");
     }
}

#pragma mark -
#pragma mark Methods

//////////// Fetch Selected Album ///////////////
- (void)fetchSelectedAlbum {
    
    GDataEntryPhotoAlbum *album = [self selectedAlbum];
    if (album) {
        
        // fetch the photos feed
        NSURL *feedURL = [[album feedLink] URL];
        if (feedURL) {
            [self setPhotoFeed:nil];
            [self setPhotoFetchError:nil];
            [self setPhotoFetchTicket:nil];
            
            GDataServiceGooglePhotos *service = [self googlePhotosService];
            GDataServiceTicket *ticket;
            ticket = [service fetchFeedWithURL:feedURL
                                      delegate:self
                             didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
            [self setPhotoFetchTicket:ticket];
            
        }
    }
}

// photo list fetch callback
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    
    [self setPhotoFeed:feed];
    [self setPhotoFetchError:error];
    [self setPhotoFetchTicket:nil];
    NSLog(@"@@@ Fecth Complete");
    
}
- (GDataEntryPhotoAlbum *)selectedAlbum {
     NSArray *albums = [mUserAlbumFeed entries];
    if([albums count]>0){
        GDataEntryPhotoAlbum *album = [albums objectAtIndex:2];  // Temp
        return album;

    }
    return Nil;
}
//////////Fetch Selected Album////////////////
- (void)fetchAllAlbums {
    
    [self setAlbumFeed:nil];
    [self setAlbumFetchError:nil];
    [self setAlbumFetchTicket:nil];
    [self setPhotoFeed:nil];
    [self setPhotoFetchError:nil];
    [self setPhotoFetchTicket:nil];
    
    NSString *username = [userNameTextField text];
    
    GDataServiceGooglePhotos *service = [self googlePhotosService];
    GDataServiceTicket *ticket;
    NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
                                                             albumID:nil
                                                           albumName:nil
                                                             photoID:nil
                                                                kind:nil
                                                              access:nil];
    ticket = [service fetchFeedWithURL:feedURL
                              delegate:self
                     didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    [self setAlbumFetchTicket:ticket];
}

// album list fetch callback
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error {
    
    NSLog(@"@@@ In callback function");
    [self setAlbumFeed:feed];
    [self setAlbumFetchError:error];
    [self setAlbumFetchTicket:nil];
    
    if (error == nil) {
        GDataFeedPhotoUser *feed = [self albumFeed];
        for (GDataEntryPhotoAlbum *albumEntry in feed) {
            NSString *title = [[albumEntry title] stringValue];
            NSLog(@"@@@ Album: %@", title);
        }
    }
}

- (GDataServiceGooglePhotos *)googlePhotosService {
    
    static GDataServiceGooglePhotos* service = nil;
    
    if (!service) {
        service = [[GDataServiceGooglePhotos alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
    }
    
    // update the username/password each time the service is requested
    NSString *username = [userNameTextField text];
    NSString *password = [passTextField text];
    if ([username length] && [password length]) {
        [service setUserCredentialsWithUsername:username
                                       password:password];
    } else {
        [service setUserCredentialsWithUsername:nil
                                       password:nil];
    }
    return service;
}

- (void)setAlbumFeed:(GDataFeedPhotoUser *)feed {
    [mUserAlbumFeed autorelease];
    mUserAlbumFeed = [feed retain];
}
- (void)setAlbumFetchError:(NSError *)error {
    [mAlbumFetchError release];
    mAlbumFetchError = [error retain];
}
- (void)setAlbumFetchTicket:(GDataServiceTicket *)ticket {
    [mAlbumFetchTicket release];
    mAlbumFetchTicket = [ticket retain];
}
- (void)setPhotoFeed:(GDataFeedPhotoAlbum *)feed {
    [mAlbumPhotosFeed autorelease];
    mAlbumPhotosFeed = [feed retain];
}
- (void)setPhotoFetchError:(NSError *)error {
    [mPhotosFetchError release];
    mPhotosFetchError = [error retain];
}
- (void)setPhotoFetchTicket:(GDataServiceTicket *)ticket {
    [mPhotosFetchTicket release];
    mPhotosFetchTicket = [ticket retain];
}
- (GDataFeedPhotoUser *)albumFeed {
    return mUserAlbumFeed; 
}
- (GDataFeedPhotoAlbum *)photoFeed {
    return mAlbumPhotosFeed; 
}

#pragma mark -
#pragma mark TextFieldDelegates
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
@end
