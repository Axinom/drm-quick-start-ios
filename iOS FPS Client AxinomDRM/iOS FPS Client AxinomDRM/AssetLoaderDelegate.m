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

typedef void(^AppCertificateRequestCompletion)(NSData *certificate);
typedef void(^ContentKeyAndLeaseExpiryRequestCompletion)(NSData *response, NSError *error);

@implementation AssetLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *url = loadingRequest.request.URL;
    if (![[url scheme] isEqual:URL_SCHEME_NAME]) {
        return NO;
    }

    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;

    [self requestApplicationCertificateWithCompletion:^(NSData *certificate) {
        NSString *assetStr = [url.absoluteString stringByReplacingOccurrencesOfString:@"skd://" withString:@""];
        NSData *assetId = [NSData dataWithBytes: [assetStr cStringUsingEncoding:NSUTF8StringEncoding] length:[assetStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];

        /*
         To obtain the Server Playback Context (SPC), we call
         AVAssetResourceLoadingRequest.streamingContentKeyRequestData(forApp:contentIdentifier:options:)
         using the information we obtained earlier.
         */
        NSError *error = nil;
        NSData *requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                                  contentIdentifier:assetId
                                                                            options:nil
                                                                              error:&error];
        // Send the SPC message to the Key Server.
        [self requestContentKeyAndLeaseExpiryfromKeyServerModuleWithRequestBytes:requestBytes
                                                             completion:^(NSData *response, NSError *error) {
                                                                 // The Key Server returns the CK inside an encrypted Content Key Context (CKC) message in response to
                                                                 // the app’s SPC message.  This CKC message, containing the CK, was constructed from the SPC by a
                                                                 // Key Security Module in the Key Server’s software.
                                                                 if (response) {
                                                                     // Provide the CKC message (containing the CK) to the loading request.
                                                                     [dataRequest respondWithData:response];
                                                                     /*
                                                                      You should always set the contentType before calling finishLoading() to make sure you
                                                                      have a contentType that matches the key response.
                                                                      */
                                                                     loadingRequest.contentInformationRequest.contentType = AVStreamingKeyDeliveryContentKeyType;
                                                                     [loadingRequest finishLoading]; // Treat the processing of the request as complete.
                                                                 }
                                                                 else {
                                                                     [loadingRequest finishLoadingWithError:error];
                                                                 }
                                                             }];
    }];

    return YES;
}

- (void)requestApplicationCertificateWithCompletion:(AppCertificateRequestCompletion)completion {
    // This needs to be implemented to conform to your protocol with the backend/key security module.
    // At a high level, this function gets the application certificate from the server in DER format.

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:FPS_CER_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *requestTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completion(data);
    }];
    [requestTask resume];
}

- (void)requestContentKeyAndLeaseExpiryfromKeyServerModuleWithRequestBytes:(NSData *)requestBytes completion:(ContentKeyAndLeaseExpiryRequestCompletion)completion {
    // Send the SPC message to the Key Server.
    // Implements communications with the Axinom DRM license server.

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:AX_DRM_LICENSE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *ksmRequest = [NSMutableURLRequest requestWithURL:url];
    [ksmRequest setHTTPMethod:@"POST"];
    [ksmRequest setHTTPBody:requestBytes];

    // Attaches the license token to license requests:
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:AX_DRM_MESSAGE];
    [ksmRequest setValue:token forHTTPHeaderField:AX_DRM_MESSAGE];

    NSURLSessionDataTask *requestTask = [session dataTaskWithRequest:ksmRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completion(data, error);
    }];
    [requestTask resume];
}

@end
