# drm-quick-start-ios

This iOS sample application demonstrates how to use Axinom DRM for the playback of HTTP Live Streaming (HLS) content protected with FairPlay Streaming (FPS). This project uses AVFoundation framework and is based on "FairPlay Streaming Programming Guide".

## Prerequisites

In order to use this sample the following prerequisities should be met:

1. Access to Apple FPS Deployment Package. This is available only to content owners and can be obtained here: https://developer.apple.com/streaming/fps/.

2. Set up Axinom DRM demo account. Registration can be performed here: https://drm.axinom.com/evaluation-account/.

3. Ability to generate Axinom DRM License Tokens. Documentation on this can be found here: https://github.com/Axinom/drm-quick-start.

## Important Files

__AssetLoaderDelegate.m__

AssetLoaderDelegate is the class that manages responding to content key requests for FairPlay Streaming protected content.

Implements communications with the Axinom DRM license server.

Attaches the license token to license requests.


__mediaResource.plist__

If you wish to add your own HLS streams to test with this sample, you can do this by adding an entry into the mediaResource.plist that is part of the Xcode Project. Keys you need to provide values for:

__media_url__: The url of the HLS stream's master playlist.

__drm_license_url__: Axinom DRM license server url.

__X-AxDRM-Message__: license token for license request.

__fps_certificate_url__: url to FPS certificate (from your Apple FPS Deployment Package).


## Requirements

### Build

Xcode 8.0 or later; iOS 10.0 SDK or later;

### Runtime

iOS 9.0 or later.
iPhone, iPad
