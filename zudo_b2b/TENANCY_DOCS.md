# Zudo Multi-Tenant Database System

This document explains how the Zudo platform handles multiple city-specific databases (e.g., Bengaluru, Coimbatore) through a unified API.

---

## 1. Architecture Overview

Zudo uses a **Dynamic Tenancy** architecture:
- **Central Database (`zudo-central`)**: Stores a mapping of every pincode to its respective city and database name.
- **City-Specific Databases**: Each city has its own independent database (e.g., `zudo-bengaluru`, `zudo-coimbatore`) containing its own products, orders, and users.
- **Unified API**: A single Node.js server handles all requests. It switches the database context on-the-fly based on a header sent by the frontend.

---

## 2. Server Implementation

### Dynamic Database Switching
The server uses a custom middleware (`server/middleware/tenant.js`) that looks for the `x-tenant-id` header in incoming requests.
- If the header is present (e.g., `x-tenant-id: zudo-bengaluru`), the server context switches to that database.
- If absent, it defaults to the primary database defined in `.env`.

### Tenancy API Endpoints
- **`GET /api/tenancy/find/:pincode`**: Returns the `dbName` and `city` for a given pincode. Used for automatic location detection.
- **`GET /api/tenancy/locations`**: Returns a list of all active cities and their `dbName`. Used for manual city selection dropdowns.

---

## 3. Frontend Integration (React / Website / Seller Panel)

To connect to the correct database, every frontend request must include the `x-tenant-id` header.

### Step 1: Implementation in `api.js` (Axios)
Update your Axios interceptor to include the tenant ID from `localStorage`:

```javascript
api.interceptors.request.use((config) => {
  // Add the database name to the headers
  const tenantId = localStorage.getItem('zudo_tenant_id');
  if (tenantId) {
    config.headers['x-tenant-id'] = tenantId;
  }
  return config;
});
```

### Step 2: Location Selection Workflow
1.  **Auto-Detect**: Fetch the user's pincode (using Geolocation) and call `GET /api/tenancy/find/:pincode`.
2.  **Manual Selection**: Call `GET /api/tenancy/locations` to show a list of cities.
3.  **Persistence**: Save the selected `dbName` to `localStorage.setItem('zudo_tenant_id', dbName)`.
4.  **Refresh**: Reload the app or clear the data cache to fetch products from the new city.

---

## 4. Mobile Integration (Flutter)

The Flutter app uses the same logic via `AppState` and `ApiService`:
- **`ApiService.tenantId`**: A static variable that holds the current `dbName`.
- **`_getHeaders()`**: A private method in `ApiService` that automatically adds the `x-tenant-id` header to every HTTP call.

---

## 5. Administrative Workflow

### Adding a New City
When a Super Admin adds a new location in the Admin Panel:
1.  The server automatically creates a new database (e.g., `zudo-mysuru`).
2.  The city details and its pincodes are saved inside that new database.
3.  The **`zudo-central`** mapping is automatically updated. 
4.  From that moment, any user entering those pincodes will automatically be switched to the new Mysuru database.

### Seeding Data
To manually populate the central mapping (e.g., after a fresh database setup), run:
```bash
cd server
node scripts/create_central_mapping.js
```

---

## 6. Best Practices
- **Isolation**: Each city's data is fully isolated. A user registered in Coimbatore will not exist in the Bengaluru database unless they register there as well.
- **Headers**: Always ensure `x-tenant-id` is sent. Without it, the server will default to the primary database, which might result in the wrong products being shown.
