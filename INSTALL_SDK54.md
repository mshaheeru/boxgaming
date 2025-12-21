# Installing Expo SDK 54 Dependencies

## Issue Fixed

The `@types/react` version has been updated to `^19.1.0` to match React Native 0.81.0 requirements.

## Installation Steps

### Option 1: Use --legacy-peer-deps (Recommended)

**Customer App:**
```bash
cd mobile-customer
npm install --legacy-peer-deps
npx expo install --fix --legacy-peer-deps
```

**Owner App:**
```bash
cd mobile-owner
npm install --legacy-peer-deps
npx expo install --fix --legacy-peer-deps
```

### Option 2: Use --force (Alternative)

If `--legacy-peer-deps` doesn't work:

**Customer App:**
```bash
cd mobile-customer
npm install --force
npx expo install --fix --force
```

**Owner App:**
```bash
cd mobile-owner
npm install --force
npx expo install --fix --force
```

## Why This Happens

React Native 0.81.0 requires `@types/react@^19.1.0`, but some packages may have peer dependency conflicts. Using `--legacy-peer-deps` tells npm to use the older (more permissive) dependency resolution algorithm, which is often needed for React Native projects.

## After Installation

1. **Check for issues:**
   ```bash
   npx expo-doctor
   ```

2. **Start the app:**
   ```bash
   npm start
   ```

3. **Clear cache if needed:**
   ```bash
   npx expo start -c
   ```

## Troubleshooting

If you still encounter issues:

1. **Delete node_modules and package-lock.json:**
   ```bash
   Remove-Item -Recurse -Force node_modules, package-lock.json
   ```

2. **Clear npm cache:**
   ```bash
   npm cache clean --force
   ```

3. **Reinstall:**
   ```bash
   npm install --legacy-peer-deps
   npx expo install --fix --legacy-peer-deps
   ```



