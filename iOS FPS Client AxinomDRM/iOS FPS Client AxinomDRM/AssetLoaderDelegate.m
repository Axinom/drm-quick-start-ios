//
//  AssetLoaderDelegate.m
//  iOS FPS Client AxinomDRM
//
//  Created by Dace Kotlere on 6/20/17.
//  Copyright © 2017 Dace Kotlere. All rights reserved.
//

#import "AssetLoaderDelegate.h"


NSString* const URL_SCHEME_NAME = @"skd";
NSString* const AX_DRM_MESSAGE = @"X-AxDRM-Message";
NSString* const AX_DRM_LICENSE_URL = @"drm_license_url";
NSString* const FPS_CER_URL = @"fps_certificate_url";

@implementation AssetLoaderDelegate

- (id)init
{
    self = [super init];
    return self;
}

- (NSData *)getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:(NSData *)requestBytes contentIdentifierHost:(NSString *)assetStr leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut
{
    // Send the SPC message to the Key Server.
    // Implements communications with the Axinom DRM license server.
    
    NSData *decodedData = nil;
    
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:AX_DRM_LICENSE_URL];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:AX_DRM_MESSAGE];
    NSMutableURLRequest *ksmRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // Attaches the license token to license requests:
    [ksmRequest setValue:token forHTTPHeaderField:AX_DRM_MESSAGE];
    
    [ksmRequest setHTTPMethod:@"POST"];
    [ksmRequest setHTTPBody:requestBytes];
    
    NSHTTPURLResponse *ksmResponse = nil;
    NSError *ksmError = nil;

    decodedData = [NSURLConnection sendSynchronousRequest:ksmRequest returningResponse:&ksmResponse error:&ksmError];

    return decodedData;
}

- (NSData *)myGetAppCertificateData
{
    NSData *certificate = nil;
    
    // This needs to be implemented to conform to your protocol with the backend/key security module.
    // At a high level, this function gets the application certificate from the server in DER format.
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:FPS_CER_URL];
    NSURLRequest *certRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSHTTPURLResponse *certResponse = nil;
    NSError *certError = nil;
    
    certificate = [NSURLConnection sendSynchronousRequest:certRequest returningResponse:&certResponse error:&certError];

    return certificate;
    
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    NSURL *url = loadingRequest.request.URL;
    NSError *error = nil;
    BOOL handled = NO;
    
    if (![[url scheme] isEqual:URL_SCHEME_NAME])
        return NO;
    
    NSString *assetStr;
    NSData *assetId;
    NSData *requestBytes;
    
    assetStr = [url.absoluteString stringByReplacingOccurrencesOfString:@"skd://" withString:@""];
    assetId = [NSData dataWithBytes: [assetStr cStringUsingEncoding:NSUTF8StringEncoding] length:[assetStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    
    // Get the application certificate:
    NSData *certificate = [self myGetAppCertificateData];

    /*
     To obtain the Server Playback Context (SPC), we call
     AVAssetResourceLoadingRequest.streamingContentKeyRequestData(forApp:contentIdentifier:options:)
     using the information we obtained earlier.
     */
    requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                      contentIdentifier:assetId
                                                                options:nil
                                                                  error:&error];
    NSData *responseData = nil;
    NSTimeInterval expiryDuration = 0.0;
    
    // Send the SPC message to the Key Server.
    responseData = [self getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:requestBytes
                                                             contentIdentifierHost:assetStr
                                                               leaseExpiryDuration:&expiryDuration
                                                                             error:&error];
    
    // The Key Server returns the CK inside an encrypted Content Key Context (CKC) message in response to
    // the app’s SPC message.  This CKC message, containing the CK, was constructed from the SPC by a
    // Key Security Module in the Key Server’s software.
    if (responseData != nil) {
        
        // Provide the CKC message (containing the CK) to the loading request.
        [dataRequest respondWithData:responseData];
        
        // Get the CK expiration time from the CKC. This is used to enforce the expiration of the CK.
        if (expiryDuration != 0.0) {
            
            AVAssetResourceLoadingContentInformationRequest *infoRequest = loadingRequest.contentInformationRequest;
            if (infoRequest) {
                infoRequest.renewalDate = [NSDate dateWithTimeIntervalSinceNow:expiryDuration];
                infoRequest.contentType = @"application/octet-stream";
                infoRequest.contentLength = responseData.length;
                infoRequest.byteRangeAccessSupported = NO;
            }
        }
        [loadingRequest finishLoading]; // Treat the processing of the request as complete.
    }
    else {
        [loadingRequest finishLoadingWithError:error];
    }
    
    handled = YES;	// Request has been handled regardless of whether server returned an error.
    
    return handled;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest
{
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

@end


