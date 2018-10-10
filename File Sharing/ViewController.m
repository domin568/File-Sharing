//
//  ViewController.m
//  File Sharing
//
//  Created by Dominik Tamiołło on 11/02/16.
//  Copyright © 2016 Dominik Tamiołło. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isOpenForConnections = NO;
    self.isConnected = NO;
    self.sendingFileSize = 0;
    self.receivePath = @"";
    [self.progress setMinValue:0.0];
    [self.progress setMaxValue:100.0];
    [self.progress setDoubleValue:0.0];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    self.isAccepted = NO;
    self.receivingFileSize = 0;
    
    
}
- (void)changeForPolish:(unsigned char *)string andLength:(int)len
{
    for (int i = 0 ; i < len;i++)
    {
        switch ((int)string[i]) {
            case 140://Ś
                string[i] = (char)83;
                break;
            case 143: // Ź
                string[i] = (char)122;
                break;
            case 156: // ś
                string[i] = (char)115;
                break;
            case 159: // ź
                string[i] = (char)122;
                break;
            case 163:
                string[i] = (char)76;
                break;
            case 165:
                string[i] = (char)65;
                break;
            case 175:
                string[i] = (char)90;
                break;
            case 179:
                string[i] = (char)108;
                break;
            case 185:
                string[i] = (char)97;
                break;
            case 191://ż
                string[i] = (char)122;
                break;
            case 198: // Ć
                string[i] = (char)67;
                break;
            case 202:
                string[i] = (char)69;
                break;
            case 209:
                string[i] = (char)78;
                break;
            case 211:
                string[i] = (char)79;
                break;
            case 230:
                string[i] = (char)99;
                break;
            case 234:
                string[i] = (char)101;
                break;
            case 241:
                string[i] = (char)110;
                break;
            case 243:
                string[i] = (char)111;
                break;
            default:
                break;
        }
    }
}
- (IBAction)openForConnections:(id)sender
{
    self.isOpenForConnections = YES;
    [self performSelectorInBackground:@selector(getConnection) withObject:nil];
}
- (void) showMessage
{
    NSAlert* msgBox = [[NSAlert alloc] init];
    [msgBox setMessageText:[NSString stringWithFormat:@"Do you want to receive %@ [ %.02f MB] ? ",self.receivingFileName,self.receivingFileSize]];
    [msgBox addButtonWithTitle: @"Yes"];
    [msgBox addButtonWithTitle:@"No"];
    
    if ([msgBox runModal] == NSAlertFirstButtonReturn)
    {
        self.isAccepted = YES;
    }
    else
    {
        self.isAccepted = NO;
    }
}
- (void) receiveFile
{
    while (self.isOpenForConnections && self.clientSocket)
    {

        unsigned char nameBuf [100];
        
        long bytesReadName;
        
        memset(nameBuf,0,sizeof(nameBuf));
        
        bytesReadName = recv(self.clientSocket,nameBuf,sizeof(nameBuf),0);
        
        [self changeForPolish:nameBuf andLength:(int)bytesReadName];
        self.receivingFileName = [[NSString alloc]initWithBytes:nameBuf length:bytesReadName encoding:NSASCIIStringEncoding];
        
        if (bytesReadName > 0 && self.receivingFileName)
        {
            
            [[self.filenameReceive cell]setTitle:self.receivingFileName];
            
            char fileSizeChar [50];
            
            memset(fileSizeChar,0,sizeof(fileSizeChar));
        
            long bytesFileSize = recv(self.clientSocket,fileSizeChar,sizeof(fileSizeChar),0);
            
            int fileSize = atoi(fileSizeChar);

            if (fileSize > 0)
            {
                self.receivingFileSize = (float)fileSize / (float) 1000000;
                [self.fileSizeField setStringValue:[NSString stringWithFormat:@"%.02f MB",self.receivingFileSize]];
                [self performSelectorOnMainThread:@selector(showMessage)withObject:nil waitUntilDone:YES];
                
                if (self.isAccepted)
                {
                    self.isAccepted = NO;
                    char accepted [1];
                    sprintf(accepted, "1");
                    send(self.clientSocket,accepted,1,0);
                    NSString * format = [NSString stringWithFormat:@"%@%s",self.receivePath,nameBuf];
                    
                    format = [format stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
                    
                    const char * filePath = [format UTF8String];
                    
                    FILE * plik = fopen(filePath, "wb");
                    if (plik)
                    {
                        char bufor [100000];
                        
                        int totalBytesRead = 0;
                        long bytesRead = 0;
                        while ((bytesRead = recv(self.clientSocket, bufor, sizeof(bufor),0)))
                        {
                            totalBytesRead+= bytesRead;
                            self.percent = (float) totalBytesRead / (float)fileSize * (float) 100;
                            fwrite(bufor,sizeof(char),bytesRead,plik);
                            [[self.percentField cell]setTitle:[NSString stringWithFormat:@"%.02f %%",self.percent]];
                            if (totalBytesRead >= fileSize)
                            {
                                self.percent = 0;
                                [self.progress setDoubleValue:(double)self.percent];
                                [[self.percentField cell]setTitle:@"Finished"];
                                fclose(plik);
                                break;
                            }
                        }
                        
                    }
                }
                else
                {
                    char accepted [1];
                    sprintf(accepted, "0");
                    send(self.clientSocket,accepted,1,0);
                    [[self.filenameReceive cell]setTitle:@"File abandoned"];
                    [self.fileSizeField setStringValue:@"0.00 MB"];
                }
            }
            
            
        }
        else
        {
            break;
        }
    }
}
- (void) updateProgress
{
    [self.progress setDoubleValue:(double)self.percent];
}
- (IBAction)closeConnections:(id)sender
{
    close(self.socketServer);
    close(self.clientSocket);
    close(self.localSocket);
    self.isOpenForConnections = NO;
    self.isConnected = NO;
    [self.color setColor:[NSColor redColor]];
}
- (void) getConnection
{
    
    struct sockaddr_in server,client;
    
    server.sin_port = htons(27020);
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_family = AF_INET;
    
    self.socketServer = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (self.socketServer < 0)
    {
        NSLog(@"Invalid socket");
        
    }
    if (bind(self.socketServer, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        NSLog(@"Failed binding");
    }
    
    [self.color setColor:[NSColor greenColor]];
    
    listen(self.socketServer, 3);
    
    socklen_t clientLength = sizeof(client);
    
    self.clientSocket = accept(self.socketServer, (struct sockaddr *)&client, &clientLength);

    if (self.clientSocket < 0)
    {
        NSLog(@"Error with accepting connection ");
    }

        char * ipConnected = inet_ntoa(client.sin_addr);
    
        NSString * ipConnectedString = [NSString stringWithUTF8String:ipConnected];

        [self.connectedToField setStringValue:[NSString stringWithFormat:@"Connected to %@",ipConnectedString]];
    
    
        self.isConnected = YES;
    
        [self performSelectorInBackground:@selector(receiveFile) withObject:nil];
    
    
}
- (IBAction)openReceive:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    NSError *error;
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        self.receivePath = [[[openPanel URLs] objectAtIndex:0] absoluteString];
        self.receivePath = [self.receivePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        
        [self.receiveFilePathShow setStringValue:self.receivePath];
    }
}
- (IBAction)openSend:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    //[openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        self.sendingFilePath = [[[openPanel URLs] objectAtIndex:0] absoluteString];
        self.sendingFilePath = [self.sendingFilePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        self.sendingFilePath = [self.sendingFilePath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        self.filenameSendString = [[[openPanel URLs] objectAtIndex:0]lastPathComponent];
        [[[self filenameSend]cell]setStringValue:self.filenameSendString];
        
        FILE * sendingFile = fopen([self.sendingFilePath UTF8String], "rb");
        fseek(sendingFile, 0, 2);
        self.fileSizeSendingFile = ftell(sendingFile);
        double mb = (double)self.fileSizeSendingFile / (double) 1000000;
        
        [self.sendingFileSize setStringValue:[NSString stringWithFormat:@"%.02f MB",mb]];
        [self.sendingFileSizeField setStringValue:[NSString stringWithFormat:@"%.02f MB",mb]];
        fclose(sendingFile);
        [self.sendingFilePathShow setStringValue:self.sendingFilePath];
    }
}
- (IBAction)connect:(id)sender
{
    [self performSelectorInBackground:@selector(connectThread) withObject:nil];
}
- (void) connectThread
{
    
    struct sockaddr_in otherSide;
    
    char * ip = [[self.ipSendingField stringValue]UTF8String];
 
    memset (&otherSide,0,sizeof(otherSide));
    otherSide.sin_port = htons(27000);
    otherSide.sin_addr.s_addr = inet_addr(ip);
    otherSide.sin_family = AF_INET;
    
    self.localSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (self.localSocket < 0)
    {
        NSLog(@"Invalid socket");
        
    }
    
    if (connect(self.localSocket, (struct sockaddr *)&otherSide, sizeof(otherSide)) != 0)
    {
        NSLog(@"Unable to connect ");
    }
    else
    {
        [self.sendingToField setStringValue:[NSString stringWithFormat:@"Sending to : %s",ip]];
    }
    
}
- (IBAction)send:(id)sender
{
    [self performSelectorInBackground:@selector(sendThread) withObject:nil];
}
- (void) sendThread
{
    if (self.fileSizeSendingFile  > 0)
    {
        
        char * filename = [self.filenameSendString UTF8String];
        send(self.localSocket, filename , strlen(filename),0);
        
        char buf [30];
        int tmp = (int)self.fileSizeSendingFile;
        int size = sprintf(buf, "%i",tmp);
        send(self.localSocket, buf , size,0);
        
        char isAccepted [1];
        
        long sizeIsAccepted = recv(self.localSocket, isAccepted , 1, 0);
        
        if (sizeIsAccepted > 0)
        {
            int intIsAccepted = atoi(isAccepted);
            
            if (intIsAccepted == 1)
            {
                FILE * file = fopen([self.sendingFilePath UTF8String], "rb");
                
                char bufFile [100000];
                
                long totalBytesSent = 0;
                
                while (ftell(file) != -1)
                {
                    long copied = fread(bufFile, 1, sizeof(bufFile), file);
                    fseek(file, -copied, SEEK_CUR);
                    long bytesSent = send(self.localSocket,bufFile,copied,0);
                    totalBytesSent += bytesSent;
                    fseek(file, bytesSent, SEEK_CUR);
                    float percentage = (float)totalBytesSent / (float) tmp * (float)100;
                    if (totalBytesSent >= tmp)
                    {
                        break;
                    }
                }
                fclose(file);
            }
        }
        
        
    }

}
- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
