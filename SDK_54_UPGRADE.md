# Expo SDK 54 Upgrade Guide

Both mobile apps have been upgraded to Expo SDK 54.

## What Changed

### Core Updates
- **Expo SDK**: `51.0.0` → `54.0.0`
- **React**: `18.2.0` → `19.1.0`
- **React Native**: `0.74.5` → `0.81.0`

### Package Updates

#### Customer App
- `expo-status-bar`: `~1.12.1` → `~2.0.0`
- `react-native-screens`: `~3.31.1` → `~4.4.0`
- `react-native-safe-area-context`: `4.10.5` → `~5.1.0`
- `@react-native-async-storage/async-storage`: `1.23.1` → `~2.1.0`
- `expo-location`: `~17.0.1` → `~18.0.0`
- `expo-image-picker`: `~15.0.7` → `~16.0.0`
- `react-native-maps`: `1.14.0` → `~2.0.0`

#### Owner App
- `expo-status-bar`: `~1.12.1` → `~2.0.0`
- `react-native-screens`: `~3.31.1` → `~4.4.0`
- `react-native-safe-area-context`: `4.10.5` → `~5.1.0`
- `@react-native-async-storage/async-storage`: `1.23.1` → `~2.1.0`
- `expo-camera`: `~15.0.0` → `~16.0.0`

### Dev Dependencies
- `@babel/core`: `^7.20.0` → `^7.25.0`
- `@types/react`: `~18.2.45` → `~19.0.0`
- `typescript`: `^5.1.3` → `^5.6.0`

## Next Steps

### 1. Delete node_modules and package-lock.json

**Customer App:**
```bash
cd mobile-customer
rm -rf node_modules package-lock.json
# Or on Windows:
# Remove-Item -Recurse -Force node_modules, package-lock.json
```

**Owner App:**
```bash
cd mobile-owner
rm -rf node_modules package-lock.json
# Or on Windows:
# Remove-Item -Recurse -Force node_modules, package-lock.json
```

### 2. Install Dependencies

**Customer App:**
```bash
cd mobile-customer
npm install
```

**Owner App:**
```bash
cd mobile-owner
npm install
```

### 3. Fix Dependency Versions (Recommended)

After installing, run Expo's dependency fixer to ensure all versions are compatible:

**Customer App:**
```bash
cd mobile-customer
npx expo install --fix
```

**Owner App:**
```bash
cd mobile-owner
npx expo install --fix
```

### 4. Check for Issues

Run Expo Doctor to check for common issues:

```bash
npx expo-doctor
```

### 5. Update Native Projects (If Needed)

If you have native code or need to rebuild:

**iOS:**
```bash
cd ios
npx pod-install
```

**Android:**
- Clean and rebuild the Android project

## Breaking Changes to Watch For

### React 19 Changes
- Some React APIs may have changed
- Check your components for deprecated patterns

### React Native 0.81 Changes
- New architecture improvements
- Some native modules may need updates

### Expo SDK 54 Features
- **React Native 0.81** with improved performance
- **React 19.1** support
- **Precompiled React Native for iOS** (faster builds)
- **iOS 26 and Liquid Glass** support
- **Android 16** enhancements

## Testing Checklist

After upgrading, test:

- [ ] App starts without errors
- [ ] Authentication flow works
- [ ] Navigation works correctly
- [ ] API calls function properly
- [ ] Camera/QR scanner works (Owner app)
- [ ] Location services work (Customer app)
- [ ] Image picker works (Customer app)
- [ ] Maps display correctly (Customer app)
- [ ] All screens render properly
- [ ] No console errors or warnings

## Troubleshooting

### If you encounter errors:

1. **Clear Expo cache:**
   ```bash
   npx expo start -c
   ```

2. **Reset Metro bundler:**
   ```bash
   npx expo start --clear
   ```

3. **Reinstall dependencies:**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   npx expo install --fix
   ```

4. **Check Expo Doctor:**
   ```bash
   npx expo-doctor
   ```

## Resources

- [Expo SDK 54 Changelog](https://expo.dev/changelog/sdk-54)
- [React 19 Release Notes](https://react.dev/blog/2024/04/25/react-19)
- [React Native 0.81 Release Notes](https://reactnative.dev/blog/2024/01/25/version-0.81)



