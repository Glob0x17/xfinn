# xfinn - Jellyfin Client for tvOS

## Project Overview
Native tvOS app for Jellyfin media server using SwiftUI and AVKit.

## Architecture
- **MVVM pattern** with BaseViewModel and ViewModelProtocol
- **Services**: AuthService, JellyfinService, PlaybackService, PlayerManager
- **Native player**: AVPlayerViewController with HLS streaming

## Playback System

### DeviceProfile Configuration
The app uses Jellyfin's DeviceProfile API to declare playback capabilities. Key decisions:

1. **Container Support**:
   - Direct Play: MP4, M4V, MOV only (AVPlayer native)
   - MKV is NOT supported by AVPlayer - must be transcoded
   - Transcoding container: `mp4` (fMP4 for HLS) - NOT `ts`

2. **Why fMP4 instead of MPEG-TS**:
   - HEVC in MPEG-TS has limited support on AVPlayer
   - Dolby Vision doesn't work in TS containers
   - fMP4 segments preserve HDR/DV metadata correctly

3. **Codec Priority**:
   - Video: `hevc,h264` (HEVC preferred for copy, H.264 fallback)
   - Audio: `aac,ac3,eac3,flac,alac`

### DeviceCapabilities Detection
Automatic detection of Apple TV model capabilities via `sysctlbyname("hw.machine")`:

| Model | Identifier | HEVC | HDR10 | DV | HDR10+ | AV1 |
|-------|-----------|------|-------|-----|--------|-----|
| 4K 3rd gen | AppleTV14,x | Yes | Yes | Yes | Yes | Yes |
| 4K 2nd gen | AppleTV11,x | Yes | Yes | Yes | No | No |
| 4K 1st gen | AppleTV6,x | Yes | Yes | Yes | No | No |
| HD | AppleTV5,x | No | No | No | No | No |

### Playback URL Selection Logic
Based on Swiftfin's approach:
1. If `transcodingUrl` exists -> use it (server decided transcoding needed)
2. Otherwise -> build Direct Stream URL with `static=true`

## Reference Implementation
Swiftfin source at `/Users/dorian/Swiftfin/` was used as reference for:
- DeviceProfile configuration
- URL construction logic
- Container/codec compatibility

## Key Files
- `DeviceProfile.swift`: Jellyfin device profile with dynamic capability detection
- `DeviceCapabilities.swift`: Apple TV model detection and capabilities
- `PlaybackService.swift`: PlaybackInfo API and URL construction
- `PlayerManager.swift`: AVPlayer lifecycle and progress reporting
