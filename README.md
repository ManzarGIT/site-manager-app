# Site Manager Pro - Full Setup Guide

Welcome to the **Site Manager Pro** application! This is a complete production-ready scaffold for a construction site management app (Khata Book clone).

## 📂 Folder Structure
```
nomad-meteorite/
│
├── backend/
│   ├── .env.example
│   ├── package.json
│   ├── server.js
│   ├── prisma/
│   │   └── schema.prisma         # PostgreSQL DB Schema
│   └── src/
│       ├── config/
│       │   └── db.js            # Prisma Client
│       ├── controllers/
│       │   ├── attendanceController.js
│       │   ├── authController.js
│       │   ├── siteController.js
│       │   ├── transactionController.js
│       │   └── workerController.js
│       ├── middlewares/
│       │   └── auth.js          # JWT & Role checking
│       ├── routes/
│       │   ├── attendanceRoutes.js
│       │   ├── authRoutes.js
│       │   ├── siteRoutes.js
│       │   ├── transactionRoutes.js
│       │   └── workerRoutes.js
│       └── utils/
│           └── encryption.js    # AES-256 for Financial notes
│
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   └── auth_provider.dart # API Client & State
        └── screens/
            ├── attendance_scanner_screen.dart # QR Scanner
            ├── dashboard_screen.dart
            ├── finances_screen.dart # Encrypted financial view
            ├── login_screen.dart
            └── worker_list_screen.dart
```

---

## 🚀 Setup Instructions

### 1. Database (PostgreSQL)
Ensure you have PostgreSQL installed and running. Create a new database (e.g., `construction_app`).

### 2. Backend Setup commands
Open a terminal in the `backend` directory:
```bash
cd backend
npm install
```

**Environment Variables:**
Rename `.env.example` to `.env` and fill in your DB connection string and secrets:
```env
PORT=5000
DATABASE_URL="postgresql://USERNAME:PASSWORD@localhost:5432/construction_app?schema=public"
JWT_SECRET="YOUR_SUPER_SECRET_JWT_KEY"
AES_ENCRYPTION_KEY="12345678901234567890123456789012" # MUST BE EXACTLY 32 CHARS
```

**Run Migrations:**
This will generate the required SQL tables in your PostgreSQL database based on `schema.prisma`.
```bash
npx prisma migrate dev --name init
```

**Start the Server:**
```bash
npm run dev
```
*The backend is now running on `http://localhost:5000`.*

### 3. Frontend Setup (Flutter)
Open a new terminal in the `frontend` directory:
```bash
cd frontend
flutter pub get
```

**Configuration Notes:**
- In `lib/core/auth_provider.dart`, the `baseUrl` is currently set to `http://10.0.2.2:5000/api` for the Android emulator. 
- If you are testing on an iOS Simulator, change it to `http://localhost:5000/api`.
- If testing on a physical device, change it to your machine's local IP address (e.g., `http://192.168.1.5:5000/api`).

**Run the App:**
```bash
flutter run
```

---

## 🔐 Key Features Embedded:
- **AES-256 Encryption:** Financial notes in `transactionController.js` are fully encrypted at rest in the DB and decrypted on the fly ONLY for authorized roles.
- **Role-Based Access Control:** Managers, Admins, Handlers, and Accountants have explicitly scoped views enforced in `middlewares/auth.js`.
- **JWT Authentication:** Stateful user session persistence using `SharedPreferences` in Flutter.
- **QR Code Scanner Integration:** Ready-to-use QR flow in `attendance_scanner_screen.dart` to mark daily Check-In/Check-Out.
