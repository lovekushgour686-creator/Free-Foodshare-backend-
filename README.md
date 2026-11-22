# FoodShare Frontend (React + Vite + Tailwind CSS)

Modern, responsive web application for **FoodShare**, enabling seamless surplus food donation, cold-chain safety logging, and nonprofit community claims.

## Tech Stack
- **Framework:** React 18 + Vite
- **Styling:** Tailwind CSS (Custom emerald and brand palette)
- **Routing:** React Router DOM (v6)
- **HTTP Client:** Axios (with Bearer JWT interceptor & auto-logout on session expiration)
- **Icons:** Lucide React (`lucide-react`)

---

## Getting Started

### 1. Environment Setup
The frontend connects to the backend API via `VITE_API_BASE_URL`.
See `.env.example` or `.env`:

```env
VITE_API_BASE_URL=http://localhost:5000/api
```

### 2. Run the Development Server

```bash
cd frontend
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## Features & UI Architecture

### 1. Centralized Authentication Gateway (`AuthGateway.jsx`) & Role-Based Navigation
- **Centralized Auth Gateway (`/auth`, `/login`, `/register`)**:
  - Unified modal/card layout featuring a surplus-food rescue palette (emerald & forest tones, warm amber accents, glassmorphic cards).
  - 3-card role selection grid:
    1. **Food Donor / Provider** (`provider`): Restaurants, bakeries, caterers, supermarkets with surplus food (redirects to `/provider`).
    2. **NGO / Organization** (`organization`): Food banks, shelters, charities claiming bulk surplus (redirects to `/ngo`).
    3. **General Recipient / Community Member** (`recipient`): Community volunteers and individuals seeking local meal distribution (redirects to `/marketplace`).
  - Interactive mode toggle between **Sign In to Your Account** and **Create New Account**.
  - Adaptive role guidance banner and custom field labels (e.g., "Business / Kitchen Name" vs "Organization / NGO Name" vs "Your Full Name").
  - Quick-test demo credentials buttons for instant 1-click test fill (`🥖 Donor Demo`, `🏢 NGO Demo`, `🤝 Community Demo`).
- **Global Auth Context (`useAuth`)**:
  - Handles login, registration, persistent JWT storage in `localStorage`, and session validation via `/api/auth/me`.
  - Roles supported: `'provider'`, `'organization'`, `'recipient'`, `'admin'`.
- **Navigation (`Navbar.jsx`)**:
  - **Public**: Home, Marketplace, Sign In, Join FoodShare.
  - **Food Provider**: Home, Marketplace, **Provider Dashboard**, Notification Bell.
  - **Charity Organization**: Home, Marketplace, **NGO Portal**, **My Claims**, Notification Bell.
  - **Community Member**: Home, Marketplace, Community Badge, Notification Bell.
  - **Unread Notification Bell**: Real-time counter badge with dropdown drawer (`NotificationDropdown.jsx`) allowing one-click read status and direct alerts for claims and safety warnings.

### 2. Surplus Food Marketplace (`Marketplace.jsx`)
- **Category Filter Pills**: Quick toggle across Bakery, Produce, Prepared Meals, Dairy, Pantry, etc.
- **Search Bar**: Instant keyword filtering across listing titles and descriptions.
- **Listing Cards (`ListingCard.jsx`)**:
  - Live expiry countdown badges with color alerts (e.g., `Expires in 4h 30m`).
  - Food quantity & unit of measurement.
  - Pickup window timeline.
  - Verified provider status.
- **Listing Detail Modal (`ListingDetailModal.jsx`)**:
  - Full item contents and allergen warnings.
  - Complete history of food safety checks (temperatures and packaging audits).
  - Provider contact details and pickup address.
  - One-click "Claim This Food" button for charities.

### 3. Food Provider Dashboard (`ProviderDashboard.jsx`)
- **Post Surplus Food Form**: Post donations with quantity, unit, expiry timestamp, pickup window start/end, and description.
- **My Listings Tab**: Monitor active donations, claim states, and open the Food Safety Check modal.
- **Food Safety Check Modal (`SafetyCheckModal.jsx`)**: Log storage temperatures (with presets for Frozen -18°C, Chilled 4°C, Hot-held 65°C), container seal integrity, and cold-chain compliance notes.
- **Incoming Claims Tab**: Review claim requests placed by charity organizations with quick **Approve**, **Reject**, and **Mark Picked Up** action buttons.

### 4. Organization Claims Tracker (`OrganizationClaims.jsx`)
- Filter by status: `Pending`, `Approved (Ready for Pickup)`, `Completed`.
- Real-time status cards showing pickup addresses and emergency provider contacts.
- Ability to cancel pending claims so food returns to the open marketplace.

---

## Project Structure

```
frontend/
├── index.html
├── package.json
├── vite.config.js
├── tailwind.config.js
├── postcss.config.js
├── .env.example
├── .env
├── src/
│   ├── main.jsx
│   ├── App.jsx
│   ├── index.css
│   ├── api/
│   │   └── axios.js            # Axios with JWT request & response interceptors
│   ├── context/
│   │   ├── AuthContext.jsx      # User profile, role checks, login/register/logout
│   │   └── NotificationContext.jsx # Polling, unread badges, mark-read actions
│   ├── components/
│   │   ├── Navbar.jsx           # Responsive navbar with role pills & notification bell
│   │   ├── Footer.jsx           # Clean footer with SDG mission
│   │   ├── ProtectedRoute.jsx   # Role guard wrapper
│   │   ├── NotificationDropdown.jsx # Real-time alerts drawer
│   │   ├── SafetyCheckModal.jsx # Log food temperature & container seals
│   │   ├── ListingCard.jsx      # Interactive card with countdowns & safety tags
│   │   └── ListingDetailModal.jsx # Detailed inspection & claim trigger
│   └── pages/
│       ├── Home.jsx             # Hero section, impact statistics, how-it-works
│       ├── AuthGateway.jsx      # Centralized role-based auth gateway & modal layout
│       ├── Login.jsx            # Sign-in portal wrapper delegating to AuthGateway
│       ├── Register.jsx         # Sign-up portal wrapper delegating to AuthGateway
│       ├── Marketplace.jsx      # Surplus food feed with filters & search
│       ├── ProviderDashboard.jsx# Listing creation, safety audits, claim management
│       ├── OrganizationClaims.jsx # Charity pickup tracker & history
│       └── NotFound.jsx         # 404 page
```

