# Mobile Apps - Complete Implementation

Both React Native apps are now complete using **React Native Paper** (Material Design 3) - a Mantine-like library for React Native.

## What's Built

### Customer App (`mobile-customer/`)

**Screens:**
- ✅ Phone OTP Login
- ✅ Home - Browse venues with search & filters
- ✅ Venue Details - View grounds and pricing
- ✅ Booking - Select date, time, and duration
- ✅ Payment - Payment method selection
- ✅ My Bookings - Upcoming and past bookings
- ✅ Booking Details - View QR code and cancel

**Features:**
- Material Design 3 UI (React Native Paper)
- Bottom tab navigation
- Pull-to-refresh
- Search and filter venues
- Sport type filtering
- Booking management

### Owner App (`mobile-owner/`)

**Screens:**
- ✅ Phone OTP Login (owner role required)
- ✅ Dashboard - Today's bookings with revenue
- ✅ QR Scanner - Scan customer QR codes

**Features:**
- Simple, large-button UI (for non-tech-savvy users)
- Today's revenue summary
- One-tap actions (Mark Started, Mark Completed)
- QR code scanner for check-in
- Auto-refresh bookings

## UI Components Used (React Native Paper)

Both apps use Material Design 3 components:

- **Buttons**: `Button` with `mode="contained"`, `mode="outlined"`, `mode="text"`
- **Cards**: `Card`, `Card.Content`, `Card.Cover`
- **Inputs**: `TextInput` with `mode="outlined"`
- **Navigation**: React Navigation with `@react-navigation/native-stack` and `@react-navigation/bottom-tabs`
- **Icons**: `MaterialCommunityIcons` from `@expo/vector-icons`
- **Chips**: `Chip` for tags and status
- **Snackbars**: `Snackbar` for notifications
- **Activity Indicators**: `ActivityIndicator` for loading
- **Segmented Buttons**: `SegmentedButtons` for duration selection

## How to Run on Your Phone

### Quick Setup (5 minutes)

1. **Find your IP address**:
   ```bash
   # Windows
   ipconfig
   
   # Mac/Linux
   ifconfig | grep "inet "
   ```

2. **Update backend CORS** (if not done):
   ```bash
   # Edit docker-compose.dev.yml
   CORS_ORIGIN: "http://localhost:3000,http://localhost:3001,http://YOUR_IP:3000"
   
   # Restart backend
   docker-compose -f docker-compose.dev.yml restart backend
   ```

3. **Setup Customer App**:
   ```bash
   cd mobile-customer
   npm install
   echo "EXPO_PUBLIC_API_URL=http://YOUR_IP:3000/api/v1" > .env
   npm start
   ```

4. **Setup Owner App** (in new terminal):
   ```bash
   cd mobile-owner
   npm install
   echo "EXPO_PUBLIC_API_URL=http://YOUR_IP:3000/api/v1" > .env
   npm start
   ```

5. **On your phone**:
   - Install **Expo Go** app
   - Make sure phone and computer are on **same WiFi**
   - Scan QR code from terminal
   - App loads on your phone!

## Testing the Connection

**Before running the app**, test from your phone's browser:

```
http://YOUR_IP:3000/api/v1/health
```

Should return: `{"status":"ok",...}`

If this works, the mobile app will connect!

## Creating Test Data

### Create an Owner User

```bash
docker-compose -f docker-compose.dev.yml exec postgres psql -U indooruser -d indoor_games -c "INSERT INTO users (id, phone, name, role, created_at) VALUES (gen_random_uuid(), '+923001234568', 'Owner User', 'owner', NOW());"
```

### Create a Venue (via API or Admin Dashboard)

Use the admin dashboard or API to create venues with grounds.

## App Structure

```
mobile-customer/
├── src/
│   ├── screens/
│   │   ├── auth/          # Login screens
│   │   ├── home/          # Venue browsing
│   │   ├── venue/         # Venue details
│   │   ├── booking/       # Booking flow
│   │   ├── bookings/      # My bookings
│   │   └── payment/       # Payment screen
│   ├── navigation/        # App navigation
│   ├── context/           # Auth context
│   ├── config/            # API config
│   └── theme.ts           # Material theme
└── App.tsx

mobile-owner/
├── src/
│   ├── screens/
│   │   ├── auth/          # Login screens
│   │   ├── dashboard/     # Today's bookings
│   │   └── scanner/       # QR scanner
│   ├── navigation/        # App navigation
│   ├── context/           # Auth context
│   ├── config/            # API config
│   └── theme.ts           # Material theme
└── App.tsx
```

## Key Features

### Customer App
- Browse venues by location and sport
- Filter by sport type (badminton, futsal, etc.)
- View available time slots
- Book 2hr or 3hr packages
- View booking history
- Cancel bookings (with refund policy)
- QR code for venue check-in

### Owner App
- Simple dashboard (one main screen)
- Large buttons for easy tapping
- Today's revenue at a glance
- QR scanner for customer check-in
- Mark bookings as started/completed
- Minimal text, icon-based UI

## Troubleshooting

### Can't connect to API
1. Check IP in `.env` matches your computer's IP
2. Test from phone browser: `http://YOUR_IP:3000/api/v1/health`
3. Verify backend is running
4. Check CORS configuration includes your IP
5. Ensure same WiFi network

### Expo Go issues
- Try tunnel mode: `expo start --tunnel`
- Clear cache: `expo start -c`
- Check Expo CLI: `npx expo --version`

### Build errors
- Run `npm install` again
- Clear node_modules and reinstall
- Check Node.js version (18+)

## Next Steps

1. **Test the apps** on your phone
2. **Create test venues** via admin dashboard
3. **Test booking flow** end-to-end
4. **Customize UI** colors and styling
5. **Add more features** as needed

Both apps are ready to use! 🚀




