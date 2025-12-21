# Original Prompt

> I want to build an Indoor Games App System.
> These days Indoor Games are on peak.
> What happens right now, they have opened their grounds and gave their phone number for booking.
>
> Me as a customer have to msg them on whatsapp ask for available slots, payment stucture, ground selection, advance payment then finally after game final payment. They charge per hour and gives you 2 hrs and 3 hrs packages based on ground size.
>
> I was thinking on automating this and charging fee from these owners. Give me proper SRS in md file (with this prompt at top).
>
> I think mobile app will be suitable for this not web app. And there should be admin portal for these owners to get latest updates of ground slots availability (or do you suggest something else given their admin ppl may not that much tech savvy)

---

# Software Requirements Specification (SRS)
## Indoor Games Booking System

**Version:** 1.0 (MVP Focus)  
**Target Market:** Pakistan (initially Karachi)  
**Primary Sports:** Badminton, Futsal, Cricket nets, Padel, Table Tennis  
**Document Purpose:** Define true MVP scope for 8-12 week build

---

## 1. Executive Summary

### 1.1 The Problem
Indoor sports venue booking is currently manual, WhatsApp-based, and inefficient:
- Customers waste time negotiating slots via messages
- Owners lose bookings due to slow responses (especially at night)
- Double bookings happen frequently
- No payment tracking (advance/final confusion)
- No show-up accountability
- Owners can't see their schedule at a glance

### 1.2 The Solution
A **mobile-first booking platform** with:
- **Customer Mobile App**: Search → View slots → Book → Pay → Show QR code
- **Owner Mobile App**: Dead-simple schedule view → Accept/reject bookings → Mark completed
- **Platform Revenue**: Commission per successful booking (8-12%)

### 1.3 Why Mobile App (Not Web)
✅ **Correct choice** because:
- 95% of your target users (both customers and owners) are mobile-first
- Customers book on-the-go (often while commuting or with friends)
- Owners check bookings throughout the day on their phones
- Push notifications are critical (web notifications have poor delivery)
- Offline capability matters (owners may have poor venue WiFi)
- WhatsApp integration works better with native apps

**Key Decision**: Build **native mobile apps** (React Native or Flutter), not PWA. PWAs look like compromise solutions and have poor App Store presence for discovery.

---

## 2. Core User Journeys

### 2.1 Customer Journey (First Time User)
1. Download app → Sign up with phone number (OTP)
2. Set location → See nearby venues with availability
3. Select sport type → See venues filtered by sport
4. Pick venue → See grounds with different sizes
5. Select date & time → See available slots
6. Choose package (2hr or 3hr) → See price
7. **Pay full amount** (not deposit - simplified for MVP)
8. Get booking confirmation with QR code
9. Arrive at venue → Show QR → Play
10. Rate experience afterward

### 2.2 Owner Journey (First Time Setup)
1. Download owner app → Sign up (verified by your team manually)
2. Create venue profile (name, address, photos, amenities)
3. Add grounds (Ground A, B, C with sizes: small/medium/large)
4. Set pricing per ground per package (2hr/3hr rates)
5. Set operating hours (e.g., 6 AM - 12 AM)
6. Mark unavailable days (e.g., maintenance Mondays)
7. **Go live** (your team approves, then visible to customers)

### 2.3 Owner Daily Usage
1. Morning: Open app → See today's bookings
2. Someone books → Get push notification with details
3. Tap notification → See booking details
4. Optionally: Accept/reject (if you enable approval mode)
5. Customer arrives → Scan their QR code → Mark "Started"
6. After game → Mark "Completed"
7. End of day → See revenue summary
8. End of week → See payout coming (after your commission deducted)

---

## 3. MVP Feature Scope

### 3.1 MUST HAVE (Phase 1 - Launch Ready)

#### Customer App
- **Auth**: Phone OTP signup/login
- **Discovery**: 
  - List venues by location (nearest first)
  - Filter by sport type
  - See venue photos, ratings, operating hours
- **Booking**:
  - Calendar view showing available/booked slots
  - Select slot → Choose package (2hr/3hr) → See price breakdown
  - **Single payment** (full amount) via JazzCash/EasyPaisa/Card
  - Instant confirmation with QR code + booking ID
- **My Bookings**: Upcoming and past bookings
- **Cancellation**: Cancel up to 4 hours before slot (80% refund)
- **Push Notifications**: Booking confirmed, reminder 2hrs before
- **Basic Profile**: Name, phone, saved cards

#### Owner App
- **Auth**: Phone OTP (role: owner, approved by platform admin)
- **Venue Setup**:
  - Add venue details (name, location, photos, description)
  - Add multiple grounds (name, sport type, size)
  - Set pricing per ground (2hr/3hr rates)
  - Set operating hours (daily or custom per day)
- **Bookings Dashboard**:
  - Today's bookings (list view with customer name, time, ground)
  - Upcoming bookings (next 7 days)
  - Past bookings (for reference)
- **QR Scanner**: Scan customer QR → Mark started → Mark completed
- **Revenue**: 
  - Today's earnings
  - This week's earnings
  - Pending payout amount (after commission)
- **Slot Management**:
  - Block specific slots (e.g., maintenance 2-4 PM)
  - Bulk block days (e.g., closed for Eid)

#### Platform Admin (Web Dashboard - For You)
- **Owner Onboarding**: Approve/reject new venue applications
- **Venue Management**: Edit, suspend, or delete venues
- **Commission Setup**: Set commission % per venue (default 10%)
- **Payout Management**: 
  - See all pending payouts
  - Mark paid (manual for MVP - you'll transfer to their bank)
  - Payout history
- **Booking Overview**: All bookings across platform
- **Revenue Dashboard**: Your commission earnings, GMV, trends
- **Customer Support**: View booking details for dispute resolution

### 3.2 NICE TO HAVE (Phase 2 - Post Launch)
- In-app chat between customer and owner
- Automated payouts (bank API integration)
- Dynamic pricing (surge on weekends)
- Recurring bookings (e.g., every Tuesday 7-9 PM)
- Team booking (split payment among friends)
- Loyalty points/credits
- Equipment rental (rackets, balls)
- Tournaments mode
- Multi-language (Urdu)

### 3.3 EXPLICITLY OUT OF SCOPE (Never)
- ❌ Post-game payment (too complex - confusing for users)
- ❌ Partial/deposit payment (banks refunds are messy)
- ❌ WhatsApp command bot (fragile, hard to maintain)
- ❌ Web app for customers (mobile-only for better UX)
- ❌ Owner desktop admin (they're all on phones)
- ❌ Cash payment handling (digital-only platform)

---

## 4. Technical Architecture

### 4.1 Recommended Tech Stack

#### Mobile Apps
**Option A: React Native (Recommended)**
- ✅ Single codebase for iOS + Android
- ✅ Your team likely knows JavaScript/TypeScript
- ✅ Great libraries for payments, maps, QR codes
- ✅ Faster development than native
- ⚠️ Slightly larger app size

**Option B: Flutter**
- ✅ Better performance than React Native
- ✅ Beautiful UI out of the box
- ⚠️ Dart language has smaller talent pool in Pakistan
- ⚠️ Some payment SDKs may require native bridges

**Recommendation**: Start with **React Native** unless your team already knows Flutter.

#### Backend
```
API: Node.js (NestJS or Express) + TypeScript
Database: PostgreSQL (for reliability and ACID compliance)
Cache: Redis (for slot locking to prevent double bookings)
File Storage: AWS S3 or Cloudflare R2 (for photos)
Push Notifications: Firebase Cloud Messaging (FCM)
Payment Gateway: Integrate JazzCash, EasyPaisa, and PayFast
Hosting: 
  - API: Railway, Render, or DigitalOcean App Platform
  - Database: Neon, Supabase, or managed PostgreSQL
  - Admin: Vercel or Netlify
```

#### Admin Dashboard
```
Framework: Next.js (React) + TypeScript
UI: Tailwind CSS + shadcn/ui components
Auth: JWT with role-based access
Hosting: Vercel
```

### 4.2 System Architecture Diagram
```
┌─────────────────┐         ┌─────────────────┐
│  Customer App   │         │   Owner App     │
│  (React Native) │         │  (React Native) │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │         HTTPS             │
         │      (REST API)           │
         └────────┬──────────────────┘
                  │
         ┌────────▼────────┐
         │   API Gateway   │
         │   (NestJS API)  │
         └────────┬────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
┌─────▼─────┐ ┌──▼───┐ ┌────▼─────┐
│PostgreSQL │ │Redis │ │ S3/R2    │
│(Bookings) │ │(Locks│ │ (Images) │
└───────────┘ └──────┘ └──────────┘
      │
      │
┌─────▼──────────┐
│ Payment Gateway│
│ (JazzCash/Easy)│
└────────────────┘
```

### 4.3 Database Schema (Core Tables)

```sql
-- Users (both customers and owners)
users (
  id UUID PRIMARY KEY,
  phone VARCHAR(15) UNIQUE NOT NULL,
  name VARCHAR(100),
  role ENUM('customer', 'owner', 'admin'),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Venues (created by owners)
venues (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES users(id),
  name VARCHAR(200) NOT NULL,
  address TEXT,
  city VARCHAR(50),
  lat DECIMAL(10,8),
  lng DECIMAL(11,8),
  description TEXT,
  photos TEXT[], -- Array of S3 URLs
  rating DECIMAL(2,1) DEFAULT 0,
  status ENUM('pending', 'active', 'suspended'),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Grounds (multiple per venue)
grounds (
  id UUID PRIMARY KEY,
  venue_id UUID REFERENCES venues(id),
  name VARCHAR(100), -- e.g., "Court A", "Net 1"
  sport_type ENUM('badminton', 'futsal', 'cricket', 'padel', 'table_tennis'),
  size ENUM('small', 'medium', 'large'),
  price_2hr DECIMAL(10,2), -- Price for 2hr package
  price_3hr DECIMAL(10,2), -- Price for 3hr package
  is_active BOOLEAN DEFAULT true
)

-- Operating Hours
operating_hours (
  id UUID PRIMARY KEY,
  venue_id UUID REFERENCES venues(id),
  day_of_week INT, -- 0=Sunday, 6=Saturday
  open_time TIME,
  close_time TIME
)

-- Bookings (the core transaction)
bookings (
  id UUID PRIMARY KEY,
  booking_code VARCHAR(10) UNIQUE, -- e.g., "BK7X3M"
  customer_id UUID REFERENCES users(id),
  ground_id UUID REFERENCES grounds(id),
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  duration_hours INT NOT NULL, -- 2 or 3
  price DECIMAL(10,2) NOT NULL,
  status ENUM('confirmed', 'started', 'completed', 'cancelled', 'no_show'),
  payment_status ENUM('paid', 'refunded'),
  payment_method VARCHAR(50),
  payment_id VARCHAR(100), -- Gateway transaction ID
  qr_code TEXT, -- Base64 or URL to QR image
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Prevent double booking
  UNIQUE(ground_id, booking_date, start_time)
)

-- Blocked Slots (for maintenance, etc.)
blocked_slots (
  id UUID PRIMARY KEY,
  ground_id UUID REFERENCES grounds(id),
  block_date DATE,
  start_time TIME,
  end_time TIME,
  reason TEXT
)

-- Payments (for accounting)
payments (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  amount DECIMAL(10,2),
  gateway VARCHAR(50), -- 'jazzcash', 'easypaisa', 'card'
  gateway_transaction_id VARCHAR(100),
  status ENUM('pending', 'success', 'failed', 'refunded'),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Payouts (to owners)
payouts (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES users(id),
  period_start DATE,
  period_end DATE,
  gross_amount DECIMAL(10,2), -- Total bookings amount
  commission_amount DECIMAL(10,2), -- Your cut
  net_amount DECIMAL(10,2), -- What owner receives
  status ENUM('pending', 'paid'),
  paid_at TIMESTAMP,
  bank_reference VARCHAR(100)
)

-- Reviews
reviews (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  customer_id UUID REFERENCES users(id),
  venue_id UUID REFERENCES venues(id),
  rating INT CHECK(rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
)
```

---

## 5. Critical Business Logic

### 5.1 Slot Generation Algorithm
```
For each ground:
  operating_hours = venue.operating_hours
  For each day:
    start = open_time
    while start + duration <= close_time:
      create_slot(ground, date, start, duration)
      start += duration
    
Check against:
  - blocked_slots table
  - existing bookings
  
Return only available slots
```

### 5.2 Booking Flow (Preventing Double Bookings)
```
1. User selects slot → API checks:
   - Is slot still available? (check bookings table)
   - Is slot blocked? (check blocked_slots table)
   
2. If available → Create Redis lock:
   Key: "slot:{ground_id}:{date}:{time}"
   TTL: 5 minutes
   
3. User proceeds to payment → Lock still held
   
4. Payment webhook received:
   - If success → Create booking (lock released)
   - If failed → Release lock
   
5. Unique constraint on DB prevents race conditions:
   UNIQUE(ground_id, booking_date, start_time)
```

### 5.3 Pricing Calculation
```
base_price = ground.price_2hr OR ground.price_3hr
platform_fee = 0 (included in commission, not shown to customer)
total = base_price

(Future: add weekend surcharge, peak hour multiplier)
```

### 5.4 Cancellation & Refund Policy
```
IF cancellation_time > 4 hours before booking:
  refund = 80% of paid amount
  (20% kept as cancellation fee)
  
ELSE IF cancellation_time <= 4 hours before:
  refund = 0
  (no-show protection for owners)

Process refund via payment gateway API
Update booking.status = 'cancelled'
Update payment.status = 'refunded'
```

### 5.5 Commission & Payout Calculation
```
Weekly payout cycle (every Monday):

For each owner:
  completed_bookings = bookings WHERE 
    owner_id = owner.id AND
    status = 'completed' AND
    created_at BETWEEN last_monday AND this_monday
  
  gross = SUM(completed_bookings.price)
  commission = gross * 0.10 (10%)
  net = gross - commission
  
  CREATE payout(owner_id, gross, commission, net, status='pending')
  
Notify owner: "Your payout of Rs. {net} will be transferred in 2-3 days"
```

---

## 6. Payment Integration

### 6.1 Supported Payment Methods (MVP)
1. **JazzCash** (largest wallet in Pakistan)
   - Direct wallet integration
   - Customer enters mobile number → OTP → Paid
   
2. **EasyPaisa** (second largest)
   - Over-the-counter (OTC) payment
   - Generate payment code → Customer pays at shop → Webhook confirms
   
3. **Debit/Credit Cards** (via PayFast or PayPro)
   - 3D Secure for fraud prevention
   - Save card for future (tokenization)

### 6.2 Payment Gateway Provider
**Recommendation**: Start with **PayFast** or **PayPro**
- Aggregates JazzCash + EasyPaisa + Cards in one integration
- Lower technical complexity than integrating each separately
- ~2-3% transaction fee (pass to customer or absorb)

### 6.3 Payment Flow
```
1. Customer clicks "Proceed to Pay"
2. App calls API: POST /bookings with payment_method
3. API creates pending booking + calls payment gateway
4. Gateway returns payment URL (or mobile SDK params)
5. App opens payment interface (WebView or native)
6. Customer completes payment
7. Gateway sends webhook to: POST /webhooks/payment
8. Webhook handler:
   - Verifies signature
   - Updates booking.status = 'confirmed'
   - Updates payment.status = 'success'
   - Generates QR code
   - Sends push notification to customer
   - Sends push notification to owner
```

### 6.4 Refund Flow
```
1. Customer cancels booking (or admin initiates refund)
2. API checks cancellation policy
3. If eligible, calls gateway refund API
4. Gateway processes refund (3-5 days to customer account)
5. Update payment.status = 'refunded'
6. Update booking.status = 'cancelled'
7. Notify customer: "Refund of Rs. X initiated"
```

---

## 7. Owner Admin - Addressing Tech-Savvy Concern

### 7.1 The Real Problem
Your concern about "admin ppl may not be tech savvy" is valid. Here's the reality:
- Many venue owners are 40-60 years old
- They're comfortable with WhatsApp but not complex apps
- They want **simple, visual, tap-based interfaces**
- They don't want to "learn software"

### 7.2 The Wrong Solution (from GPT response)
❌ WhatsApp command bot like `CLOSE 7-9PM`, `CONFIRM ABC123`
- Too error-prone ("did I type it right?")
- No visual confirmation
- Hard to remember commands
- Feels like going backward from WhatsApp's current manual process

### 7.3 The Right Solution: Dead-Simple Mobile App

**Design Principles:**
1. **One primary screen**: Today's Schedule
2. **Big buttons**: 1cm x 1cm tap targets minimum
3. **Minimal text**: Use icons and colors
4. **No hidden menus**: Everything on main screen
5. **Instant feedback**: "Booking marked complete ✓"

**Owner App Main Screen:**
```
┌─────────────────────────────────────┐
│  🏟️  My Venue                      │
│  📅  Today - Monday, Nov 14         │
├─────────────────────────────────────┤
│                                     │
│  📊  Today's Summary                │
│  ┌─────────────────────────────┐  │
│  │  5 Bookings    Rs. 12,500   │  │
│  └─────────────────────────────┘  │
│                                     │
│  ⏰  Upcoming Bookings              │
│  ┌─────────────────────────────┐  │
│  │  8:00 AM - 10:00 AM         │  │
│  │  Court A • Ahmed Khan       │  │
│  │  📱 0300-1234567           │  │
│  │  [Scan QR]  [Mark Done ✓]  │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │  11:00 AM - 1:00 PM         │  │
│  │  Court B • Sara Ali         │  │
│  │  📱 0321-9876543           │  │
│  │  [Scan QR]  [Mark Done ✓]  │  │
│  └─────────────────────────────┘  │
│                                     │
│  + Block a Time Slot               │
│  📋  View All Bookings             │
│  💰  This Week's Earnings          │
└─────────────────────────────────────┘
```

**Key Features:**
1. **No login required after first time** (biometric/FaceID)
2. **Push notifications** for new bookings
3. **Tap booking** → See customer details + call button
4. **QR Scanner built-in** (one tap to open camera)
5. **Visual calendar** (tap to block slots)
6. **Automatic refresh** (no pull-to-refresh needed)

### 7.4 Training & Onboarding
```
When you onboard a new venue:
1. Visit them in person (or video call)
2. Install app on their phone
3. Show them the ONE main screen
4. Explain: "Green = done, White = upcoming, Red = problem"
5. Practice scanning a test QR code
6. Give them your support number
7. Send them a 1-minute video tutorial (Urdu)

Total training time: 15 minutes
```

### 7.5 Fallback: Web Admin (Not Recommended for MVP)
If you still want web admin:
- Build as **responsive web app** (same backend API)
- But expect low usage (most owners won't use it)
- Better to spend time making mobile app perfect

---

## 8. Non-Functional Requirements

### 8.1 Performance
- Slot availability API: < 500ms response time
- Payment processing: < 5 seconds end-to-end
- QR code generation: < 200ms
- App launch: < 2 seconds cold start
- Image upload: < 5 seconds for 5 photos

### 8.2 Scalability
- Support 100 venues simultaneously (MVP target)
- Handle 1,000 bookings/day across platform
- Database: vertical scaling sufficient (horizontal later)
- API: stateless, can add more servers easily

### 8.3 Reliability
- 99.5% uptime (allows ~3.6 hours downtime/month)
- Automated database backups (daily)
- Payment webhook retries (up to 5 times with exponential backoff)
- Graceful degradation (if payments down, allow booking with "pay at venue" option)

### 8.4 Security
- HTTPS everywhere
- JWT tokens with 24hr expiry
- Phone OTP valid for 5 minutes
- Payment data never stored (PCI-DSS compliance via gateway)
- API rate limiting: 100 requests/minute per IP
- QR codes expire after use (can't reuse)

### 8.5 Compliance
- GDPR-inspired data privacy (user can delete account)
- Transaction records kept for 5 years (tax purposes)
- Clear refund policy shown before payment
- Terms of Service agreement on signup

---

## 9. MVP Development Plan

### Phase 1: Foundation (Weeks 1-3)
- [ ] Backend API setup (NestJS + PostgreSQL + Redis)
- [ ] Database schema + migrations
- [ ] User authentication (phone OTP)
- [ ] Basic CRUD for venues, grounds, operating hours
- [ ] Slot generation algorithm
- [ ] Booking creation (without payment)
- [ ] Admin dashboard (venue approval)

### Phase 2: Mobile Apps (Weeks 4-6)
- [ ] Customer app UI (React Native)
  - [ ] Signup/login
  - [ ] Browse venues
  - [ ] View slots
  - [ ] Booking flow (mock payment)
  - [ ] My bookings
- [ ] Owner app UI
  - [ ] Dashboard
  - [ ] View bookings
  - [ ] Mark completed
  - [ ] Block slots

### Phase 3: Payments (Weeks 7-8)
- [ ] Integrate PayFast (or chosen gateway)
- [ ] Payment webhook handling
- [ ] QR code generation
- [ ] Refund processing
- [ ] Push notifications (FCM)

### Phase 4: Polish (Weeks 9-10)
- [ ] Bug fixes from internal testing
- [ ] Performance optimization
- [ ] Error handling improvements
- [ ] Loading states, empty states
- [ ] Cancellation flow
- [ ] Reviews/ratings

### Phase 5: Launch (Weeks 11-12)
- [ ] Onboard 5-10 pilot venues (manually)
- [ ] Soft launch to friends/family
- [ ] Monitor bugs and crashes
- [ ] Collect user feedback
- [ ] Fix critical issues
- [ ] Public launch + marketing

---

## 10. Monetization Strategy

### 10.1 Revenue Model: Commission Per Booking
```
You charge: 10% of booking amount
Example:
  Customer pays Rs. 2,000 for 2hr slot
  Owner receives: Rs. 1,800
  You keep: Rs. 200

Why this works:
✅ Owner only pays when they earn (no upfront cost)
✅ Aligned incentives (you want them to get more bookings)
✅ Easy to understand and calculate
```

### 10.2 Alternative: Freemium SaaS
```
Free Plan:
  - 10% commission per booking
  - Basic features

Pro Plan (Rs. 5,000/month):
  - 5% commission (lower)
  - Priority listing
  - Advanced analytics
  - Custom branding

Why this might not work for MVP:
❌ Owners won't pay monthly upfront (trust issues)
❌ Adds complexity to onboarding
✅ Consider after you have 50+ venues
```

### 10.3 Financial Projections (Rough)
```
Assumptions:
- 20 venues onboarded in first 3 months
- Average 5 bookings/day per venue
- Average booking value: Rs. 2,000
- Commission: 10%

Monthly Revenue:
  20 venues × 5 bookings × 30 days × Rs. 2,000 × 10%
  = Rs. 600,000/month
  = ~$2,150/month at current rates

Costs:
  - Hosting: $100/month
  - Payment gateway fees: 2.5% (split with owner)
  - Your time/team: Variable
  
Net: ~$2,000/month after 3 months
```

---

## 11. Risks & Mitigation

### 11.1 Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Payment gateway downtime | High | Fallback to "pay at venue" option |
| Double booking bug | Critical | Redis locks + DB unique constraint + thorough testing |
| App crashes on low-end phones | Medium | Test on budget Android devices (Rs. 15k phones) |
| Slow slot loading | Medium | Redis caching + optimize query |

### 11.2 Business Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Owners don't want to pay commission | High | Pilot with 5 venues, prove value first |
| Customers don't trust app payments | Medium | Partner with known venues first (social proof) |
| WhatsApp booking still preferred | Medium | Make app significantly faster & easier |
| Competitors (like Jugaadu) | Medium | Better UX, owner focus, local support |

### 11.3 Operational Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Manual payouts take too much time | Medium | Automate after 20+ venues |
| Customer support overwhelms you | Medium | Build comprehensive FAQs, in-app support |
| Venues go offline without notice | Low | Require 24hr notice or auto-disable |

---

## 12. Success Metrics

### 12.1 Launch Metrics (First 3 Months)
- **Venues onboarded**: 20 (aggressive) or 10 (realistic)
- **Active customers**: 500+
- **Bookings per week**: 200+
- **Booking completion rate**: >60% (from view to payment)
- **Cancellation rate**: <10%
- **App crashes**: <1% of sessions
- **Customer rating**: >4.0/5.0

### 12.2 Long-term Metrics (6-12 Months)
- **Venues**: 50-100
- **Customers**: 5,000+
- **GMV**: Rs. 10M+/month
- **Owner satisfaction**: >80% would recommend
- **Repeat booking rate**: >40%

---

## 13. Open Questions (Decide Before Building)

### 13.1 Business Questions
1. **Commission rate**: 10% or tiered (10% first month, 8% after)?
2. **Cancellation policy**: 4hr cutoff or 6hr? 80% refund or 50%?
3. **Launch city**: Karachi only or also Lahore/Islamabad?
4. **Target sports**: All 5 or start with just badminton + futsal?
5. **Customer support**: In-app chat or WhatsApp number or both?

### 13.2 Technical Questions
1. **React Native or Flutter?** (Choose based on team skillset)
2. **Hosting provider**: Railway ($5-20/mo) or AWS (more complex)?
3. **Push notifications**: Firebase (free) or OneSignal (better analytics)?
4. **SMS OTP provider**: Twilio ($$$) or local provider like Unifonic?
5. **Image optimization**: Compress on client or server?

### 13.3 Product Questions
1. **Booking approval**: Auto-confirm or let owner approve first?
   - Auto-confirm = faster, more bookings
   - Manual approve = owners feel in control
   - **Recommendation**: Auto-confirm with owner ability to cancel
   
2. **Payment split**: Customer pays platform (you) or venue directly?
   - **Recommendation**: Customer → Platform → Owner (you hold money)
   
3. **Multi-sport venues**: If venue has badminton + futsal courts, separate listings?
   - **Recommendation**: Single venue, multiple grounds with sport tags

---

## 14. Post-MVP Roadmap

### Version 1.1 (Month 