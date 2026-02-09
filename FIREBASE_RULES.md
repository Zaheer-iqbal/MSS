# Firebase Security & Data Structure Guide

This guide ensures your Firebase project is secure and correctly structured for role-based authentication.

## 1. Firestore Security Rules
Copy and paste these into your Firebase Console (Build > Firestore Database > Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper to check if user is logged in
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper to get user role
    function getRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    // Users collection: Anyone can create (signup), 
    // but only the owner or an admin can read/write their own data
    match /users/{userId} {
      allow create: if isSignedIn();
      allow read, update: if isSignedIn() && (request.auth.uid == userId || getRole() == 'school');
      allow delete: if false; // Prevention of accidental deletion
    }

    // Example: School collection (Only accessible by School Admins)
    match /school_data/{document=**} {
      allow read, write: if isSignedIn() && getRole() == 'school';
    }

    // Example: Attendance (Teachers and Admins can write, Parents can read their child's data)
    match /attendance/{document=**} {
      allow write: if isSignedIn() && (getRole() == 'teacher' || getRole() == 'school');
      allow read: if isSignedIn();
    }
  }
}
```

## 2. Authentication Configuration
In your Firebase Console (Build > Authentication):
1.  **Sign-in method**: Enable `Email/Password`.
2.  **Settings**: Ensure `One account per email address` is selected (default).

## 3. Recommended Firestore Structure
For a professional school app, follow this structure:

- **users** (collection)
  - **{uid}** (document)
    - `name`: "John Doe"
    - `email`: "john@example.com"
    - `role`: "teacher" // or 'school', 'head_teacher', 'parent'
    - `createdAt`: Timestamp

- **schools** (collection)
  - **{schoolId}** (document)
    - `name`: "International High School"
    - `ownerId`: "{uid}"

- **students** (collection)
  - **{studentId}** (document)
    - `name`: "Alice"
    - `parentId`: "{parentUid}"
    - `classId`: "{classId}"
