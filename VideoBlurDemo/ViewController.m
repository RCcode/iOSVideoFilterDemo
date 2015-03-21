//
//  ViewController.m
//  VideoBlurDemo
//
//  Created by MAXToooNG on 15/3/3.
//  Copyright (c) 2015年 Chen.Liu. All rights reserved.
//

#import "ViewController.h"
#import <SCRecorder.h>
#import "EditViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
@interface ViewController ()
{
    SCRecorder *_recorder;
    SCRecordSession *_recordSession;
}
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, 0, 100,100);
    btn.center = self.view.center;
    [btn setTitle:@"选择视频" forState: UIControlStateNormal];
    [btn addTarget:self action:@selector(chooseBtnOnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    _recorder = [SCRecorder recorder];
    _recorder.sessionPreset = [SCRecorderTools bestSessionPresetCompatibleWithAllDevices];
    _recorder.maxRecordDuration = CMTimeMake(60, 1);
    
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)chooseBtnOnClicked:(UIButton *)btn
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    self.imagePicker.videoMaximumDuration = 60;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.delegate = self;
    [self presentViewController:self.imagePicker animated:YES completion:^{
        
    }];
}

- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBuffer:(SCRecordSession *)recordSession {
    //    NSLog(@"Skipped video buffer");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    NSLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    NSLog(@"Reconfigured video input: %@", videoInputError);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSLog(@"url == %@",info[UIImagePickerControllerMediaURL]);
    NSURL *url = info[UIImagePickerControllerMediaURL];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *filePathTemp = [documentDirectory stringByAppendingPathComponent:@"/videoTemp2/"];
    if (![fileManager fileExistsAtPath:filePathTemp]) {
        [fileManager createDirectoryAtPath:filePathTemp withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSMutableString *s = [NSMutableString stringWithFormat:@"%@/%@%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/videoTemp2/"],@"tempVideo",@".mp4"];
    if ([fileManager fileExistsAtPath:s])
    {
        [fileManager removeItemAtPath:s error:nil];
    }
    NSData *myData = [[NSData alloc] initWithContentsOfURL:info[UIImagePickerControllerMediaURL]];
    BOOL success = [myData writeToFile:s atomically:YES];
    if (success)
    {
        NSURL *sourceMovieURL = [NSURL fileURLWithPath:s];
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
        CGSize videoSize = [[[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
        NSLog(@"%f,%f",videoSize.width,videoSize.height);
        AVAssetTrack *clipVideoTrack = [[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        CGAffineTransform videoTransform = clipVideoTrack.preferredTransform;
        BOOL isVideoAssetPortrait_ = NO;
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            isVideoAssetPortrait_ = YES;
        }
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            
            isVideoAssetPortrait_ = YES;
        }
        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
            isVideoAssetPortrait_  = NO;
        }
        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
            isVideoAssetPortrait_  = NO;
        }
        float height,width;
        if (isVideoAssetPortrait_)
        {
            height = videoSize.width;
            width = videoSize.height;
        }
        else
        {
            height = videoSize.height;
            width = videoSize.width;
        }
        
        float rate = width/height;
        if (rate >= 1)//横屏
        {
            if(height>640)
            {
                [picker dismissViewControllerAnimated:YES completion:nil];
                [self changeVideo:sourceMovieURL toSize:CGSizeMake(640*rate, 640)];
            }
            else
            {
                __weak ViewController *mainViewController = self;
                if (success) {
                    [picker dismissViewControllerAnimated:YES completion:^{
                        [mainViewController performSelectorOnMainThread:@selector(presentEditView:) withObject:s waitUntilDone:NO];
                    }];
                }
            }
        }
        else//竖屏
        {
            if(width>640)
            {
                [picker dismissViewControllerAnimated:YES completion:nil];
                [self changeVideo:sourceMovieURL toSize:CGSizeMake(640, 640.0/rate)];
            }
            else
            {
                __weak ViewController *mainViewController = self;
                if (success) {
                    [picker dismissViewControllerAnimated:YES completion:^{
                        [mainViewController performSelectorOnMainThread:@selector(presentEditView:) withObject:s waitUntilDone:NO];
                    }];
                }
                
            }
        }

    }
    else
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)changeVideo:(NSURL *)url toSize:(CGSize)size
{
    //    showLoadingView(nil);
//    [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
    AVMutableComposition* composition = [AVMutableComposition composition];
    
    AVURLAsset* firstAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
    float fps=0.00;
    AVAssetTrack * videoATrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    if(videoATrack)
    {
        fps = videoATrack.nominalFrameRate;
    }
    
    AVMutableCompositionTrack *firstTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    if ([[firstAsset tracksWithMediaType:AVMediaTypeAudio] count]>0) {
        AVMutableCompositionTrack *firstAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    [transformer setTransform:videoATrack.preferredTransform atTime:kCMTimeZero];
    
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    if (fps>0) {
        videoComposition.frameDuration = CMTimeMake(1, fps);
    }
    else
    {
        videoComposition.frameDuration = CMTimeMake(1, 30);
    }
    NSLog(@"%lld,%d",firstAsset.duration.value,firstAsset.duration.timescale);
    videoComposition.renderSize = size;
    videoComposition.renderScale = 1.0;
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480] ;
    //    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    
    NSMutableString *s = [NSMutableString stringWithFormat:@"%@/%@%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"],@"finishedVideoaaa",@".mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:s])
        [[NSFileManager defaultManager] removeItemAtPath:s error:nil];
    exporter.outputURL=[NSURL fileURLWithPath:s];
    //    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    exporter.outputFileType=AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    //    exporter.fileLengthLimit = 10*1024*1024;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [firstAsset duration]);
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        
        if (AVAssetExportSessionStatusCompleted == exporter.status) {
            [self performSelectorOnMainThread:@selector(success:) withObject:s waitUntilDone:NO];
        } else if (AVAssetExportSessionStatusFailed == exporter.status) {
            NSLog(@"%@",exporter.error);
//            [MBProgressHUD hideAllHUDsForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            //            hideLoadingView();
        } else {
            NSLog(@"Export Session Status: %ld", (long)exporter.status);
        }
    }];
    NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)self));
}


- (void)success:(NSString *)path
{
    
    [self performSelectorOnMainThread:@selector(presentEditView:) withObject:path waitUntilDone:NO];
}

- (void)presentEditView:(NSString *)filePath
{
    EditViewController *editVideoViewController = [[EditViewController alloc]initWithEditFilePath:filePath];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [_recorder.recordSession addSegment:url];
    _recordSession = [SCRecordSession recordSession];
    [_recordSession addSegment:url];
    editVideoViewController.recordSession = _recordSession;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editVideoViewController];
      [self presentViewController:nav animated:YES completion:nil];
//    //    showLoadingView(nil);
//    [MBProgressHUD hideAllHUDsForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
