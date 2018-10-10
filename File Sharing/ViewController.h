//
//  ViewController.h
//  File Sharing
//
//  Created by Dominik Tamiołło on 11/02/16.
//  Copyright © 2016 Dominik Tamiołło. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "NSProgressIndicator+ESSProgressIndicatorCategory.h"
#include <stdio.h>

@interface ViewController : NSViewController
- (IBAction)closeConnections:(id)sender;
@property (weak) IBOutlet NSTextField *percentField;
- (IBAction)connect:(id)sender;
@property (weak) IBOutlet NSColorWell *color;
@property (weak) IBOutlet NSTextField *filenameSend;
@property (weak) IBOutlet NSTextField *sendingFileSize;
@property (weak) IBOutlet NSTextField *sendingFileSizeField;

@property (weak) IBOutlet NSTextField *sendingFilePathShow;
@property (weak) IBOutlet NSTextField *receiveFilePathShow;
@property (weak) IBOutlet NSTextField *sendingToField;

@property (strong,nonatomic) IBOutlet NSProgressIndicator *progress;
@property (strong) IBOutlet NSTextField *filenameReceive;

@property (assign) float percent;
@property (weak) IBOutlet NSTextField *ipSendingField;

@property NSString * filenameSendString;

@property (assign) int socketServer;
@property (assign) int clientSocket;
@property (assign) int localSocket;
@property (assign) long  fileSizeSendingFile;
@property (weak) IBOutlet NSTextField *connectedToField;
@property (weak) IBOutlet NSTextField *fileSizeField;
@property (strong) NSString * receivePath;
@property (strong) NSString * sendingFilePath;
@property (assign) BOOL isOpenForConnections;
@property (assign) BOOL isConnected;

@property (assign) BOOL isAccepted;

@property NSString * receivingFileName;
@property float receivingFileSize;

@property NSTimer * timer;
@end

