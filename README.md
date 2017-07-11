# drm-quick-start-ios

This iOS sample application demonstrates HTTP Live Streams (HLS) videos play back with FairPlay Streaming (FPS) Content Protection using Axinom DRM. 
This project uses AVFoundation framework and it is based on "FairPlay Streaming Programming Guide".

In order to use this sample you must have Apple FPS Deployment Package which you can request from here - https://developer.apple.com/streaming/fps/.

in addition, to get access to license server URL and credentials to use it, you have to request Axinom DRM demo account, which can be done from here - https://drm.axinom.com/evaluation-account/

Additional documentation on creating X-AxDRM-Message and trying out DRM on other platforms can be found here - https://github.com/Axinom/drm-quick-start

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
