# Physical Device Setup Guide

## Problem
When running the Flutter app on a **physical Android device**, it cannot connect to the backend server running in Docker because:
- Physical devices cannot use `10.0.2.2` (this IP only works for Android emulators)
- They need the actual IP address of your computer running Docker

## Solution

### Step 1: Find Your Computer's IP Address

**Windows:**
```powershell
ipconfig | Select-String -Pattern "IPv4"
```
Look for the IP address under your active network adapter (usually starts with `192.168.x.x` or `10.x.x.x`)

**Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# or
ip addr show | grep "inet "
```

### Step 2: Update the API Base URL

1. Open `lib/core/network/api_client.dart`
2. Find the line with `const String hostIp = '10.5.54.45';`
3. Replace `10.5.54.45` with your computer's IP address

Example:
```dart
const String hostIp = '192.168.1.100'; // Your computer's IP
```

### Step 3: Ensure Docker Backend is Running

Make sure your Docker backend is running and accessible:
```bash
cd backend
docker-compose up -d
```

Verify it's accessible:
```bash
# From your computer
curl http://localhost:4000/healthz

# Should return: {"status":"ok"}
```

### Step 4: Ensure Devices are on Same Network

- Your computer and physical device must be on the **same Wi-Fi network**
- If using mobile data, it won't work (use Wi-Fi)

### Step 5: Check Windows Firewall

Windows Firewall might block incoming connections. To allow:

1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Firewall"
3. Find "Node.js" or add a rule for port 4000
4. Allow both Private and Public networks

Or via PowerShell (run as Administrator):
```powershell
New-NetFirewallRule -DisplayName "Flutter Backend" -Direction Inbound -LocalPort 4000 -Protocol TCP -Action Allow
```

### Step 6: Rebuild and Test

```bash
flutter clean
flutter pub get
flutter build apk --release
# or
flutter run --release
```

## Alternative: Use Environment Variable

You can also set the API URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:4000
```

Or for release build:
```bash
flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_IP:4000
```

## Troubleshooting

### "Connection refused" or "Network error"
1. Verify Docker is running: `docker ps`
2. Verify backend is accessible: `curl http://localhost:4000/healthz`
3. Check your IP address hasn't changed
4. Ensure device and computer are on same network
5. Check Windows Firewall settings

### "Connection timeout"
1. Check if your computer's IP changed (DHCP might assign new IP)
2. Verify port 4000 is not blocked by firewall
3. Try pinging your computer from the device (if possible)

### Still not working?
1. Try accessing `http://YOUR_IP:4000/healthz` from your phone's browser
2. If that works, the issue is in the Flutter app configuration
3. If that doesn't work, check firewall/network settings

## Current Configuration

- **Computer IP**: `10.5.54.45` (update this in `api_client.dart` if different)
- **Backend Port**: `4000`
- **API URL**: `http://10.5.54.45:4000`

## Notes

- The IP address might change if you reconnect to Wi-Fi (DHCP)
- For production, use a static IP or domain name
- Consider using a service like ngrok for testing if networks are separate

