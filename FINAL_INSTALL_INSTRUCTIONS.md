# Final Installation Instructions for SDK 54

I've created installation scripts that will handle everything automatically. The scripts are running in the background.

## What's Happening

Two PowerShell scripts are running:
1. `mobile-customer/install-sdk54.ps1` - Installing customer app dependencies
2. `mobile-owner/install-sdk54.ps1` - Installing owner app dependencies

## If Scripts Don't Complete Automatically

Run these commands manually:

### Customer App:
```powershell
cd mobile-customer
powershell -ExecutionPolicy Bypass -File install-sdk54.ps1
```

### Owner App:
```powershell
cd mobile-owner
powershell -ExecutionPolicy Bypass -File install-sdk54.ps1
```

## Manual Installation (If Scripts Fail)

### Step 1: Clean
```powershell
cd mobile-customer
Remove-Item -Recurse -Force node_modules, package-lock.json
```

### Step 2: Install Expo
```powershell
npm install expo@~54.0.0 --legacy-peer-deps
```

### Step 3: Install All Dependencies
```powershell
npm install --legacy-peer-deps
```

### Step 4: Fix Versions
```powershell
npx expo install --fix
```

## After Installation

Once installation completes:

1. **Verify installation:**
   ```powershell
   npx expo-doctor
   ```

2. **Start the app:**
   ```powershell
   npm start
   ```

## Troubleshooting

If you get version errors:

1. **Remove problematic packages from package.json** (like react-native-maps version constraint)
2. **Let expo install handle it:**
   ```powershell
   npx expo install react-native-maps expo-location expo-image-picker expo-camera
   ```

3. **Or install without version constraints:**
   ```powershell
   npm install react-native-maps expo-location expo-image-picker --legacy-peer-deps
   ```

The installation scripts should complete automatically. Check the terminal windows for progress!



