//
//  AssetLoaderDelegate.m
//  iOS FPS Client AxinomDRM
//
//  Created by Axinom.
//  Copyright (c) Axinom. All rights reserved.
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

         // To obtain the license request (Server Playback Context or SPC in Apple's terms), we call
         // AVAssetResourceLoadingRequest.streamingContentKeyRequestData(forApp:contentIdentifier:options:)
         // using the information we obtained earlier.
        NSError *error = nil;
        NSData *requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                                  contentIdentifier:assetId
                                                                            options:nil
                                                                              error:&error];
        // Send the license request to the license server. The encrypted license response (Content Key
        // Context or CKC in Apple's terms) will contain the content key and associated playback policies.
        [self requestContentKeyAndLeaseExpiryfromKeyServerModuleWithRequestBytes:requestBytes
                                                             completion:^(NSData *response, NSError *error) {
                                                                 if (response) {
                                                                     // Provide license response to the loading request.
                                                                     [dataRequest respondWithData:response];
                                                                     // You should always set the contentType before calling finishLoading() to make sure you
                                                                     // have a contentType that matches the key response.                                                                    */
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
    // This function gets the FairPlay application certificate, expected in DER format, from the
    // configured URL. In general, the logic to obtain the certificate is up to the playback app
    // implementers. Implementers should use their own certificate, received from Apple upon request.

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
    // Implements communications with the Axinom DRM license server.

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    // Send the license request to the license server.
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
