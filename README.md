# FoodShare Backend API (MySQL)

Node.js and Express REST API for **FoodShare**, a surplus food redistribution platform connecting food providers (restaurants, grocery stores, bakeries) with nonprofit organizations and charities.

## Tech Stack
- **Runtime:** Node.js (v18+)
- **Framework:** Express.js
- **Database:** MySQL 8.0+ (using `mysql2/promise` with connection pooling)
- **Authentication:** JWT (`jsonwebtoken`) & password hashing (`bcrypt`)
- **Environment Management:** `dotenv`

---

## Getting Started

### 1. Environment Setup
Configure your MySQL database credentials in `.env`:

```env
PORT=5000
NODE_ENV=development

# MySQL Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=foodshare
DB_PORT=3306

# JWT Authentication
JWT_SECRET=foodshare_jwt_super_secret_key_change_in_production_2026
JWT_EXPIRES_IN=24h

# Client Application URL (for CORS)
CLIENT_URL=http://localhost:3000
```

### 2. Database Migration / Initialization
Ensure MySQL service (e.g., XAMPP, WampServer, or local MySQL 8) is running. Initialize all tables, ENUMs, foreign keys, and indexes from `schema.sql`:

```bash
npm run db:init
```

### 3. Run the Development Server
Starts the server with automatic restart on file changes using `nodemon`:

```bash
npm run dev
```

The server starts at `http://localhost:5000`.

---

## API Documentation

### 1. Authentication (`/api/auth`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | Public | Register user (`name`, `email`, `password`, `role`: `provider`\|`organization`\|`recipient`\|`admin`, `phone`, `address`). Returns JWT token and profile. |
| `POST` | `/api/auth/login` | Public | Login with `email` and `password`. Returns JWT token and profile. |
| `GET` | `/api/auth/me` | Authenticated | Retrieve the authenticated user's current profile. |

### 2. Food Listings (`/api/listings`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/listings` | Public | Fetch available, unexpired listings. Optional query params: `?category=Bakery`, `?search=bread`, `?limit=20`, `?offset=0`. |
| `GET` | `/api/listings/ngo-feed` | Public | Live NGO Portal feed returning active, unclaimed, unexpired listings (`status = 'available'`, `claimed_by IS NULL`) with safety telemetry. |
| `GET` | `/api/listings/:id` | Public | Fetch details for a specific listing including its recorded food safety checks. |
| `POST` | `/api/listings` | `provider`, `admin` | Create a new food listing with pickup window timestamps, quantity, category, and expiry. |

### 3. Food Claims (`/api/claims`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/claims` | `organization`, `admin` | Claim an available listing (`listing_id` in body). Changes listing status to `reserved` and notifies provider. |
| `POST` | `/api/claims/:id` | `organization`, `admin` | Atomically claim an available, unexpired listing by ID (`status = 'claimed'`, `claimed_by = user_id`), record in `food_claims`, and notify provider. |
| `GET` | `/api/claims/my` | Authenticated | Fetch claims relevant to the logged-in user (`organization` sees their claims, `provider` sees incoming claims). |
| `PATCH` | `/api/claims/:id/status` | Authenticated | Update claim status (`approved`, `rejected`, `completed`, or `cancelled`). Synchronizes listing status and notifies users. |

### 4. Food Safety Checks (`/api/safety`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/safety` | Authenticated | Record temperature (`temperature_celsius`), packaging integrity (`packaging_intact`), and inspection `notes` for a listing. |
| `GET` | `/api/safety/listing/:listingId` | Public | Retrieve safety check logs for a specific listing. |

### 5. Notifications (`/api/notifications`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/notifications` | Authenticated | Fetch notifications for user (supports `?unread_only=true`). |
| `PATCH` | `/api/notifications/:id/read` | Authenticated | Mark a specific notification as read. |
| `PATCH` | `/api/notifications/read-all` | Authenticated | Mark all notifications for the user as read. |

### 6. NGO Profiles (`/api/ngos` & `/api/ngo`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/ngos/profile` | Authenticated | Retrieve the NGO profile (`reg_id`, `location`, `contact_info`, `notification_status`, `radius_km`) for the logged-in organization. |
| `POST` | `/api/ngos/profile` | `organization`, `admin` | Create or update the organization's NGO profile. |
| `PATCH` | `/api/ngos/notifications` | Authenticated | Update NGO notification preferences (`notification_status: true/false`). |
| `GET` | `/api/ngos/all` | Public | List all registered NGO profiles and service coverage areas. |

### 7. Health Check (`/api/health`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/health` | Public | Checks MySQL database connectivity and returns service status. |
