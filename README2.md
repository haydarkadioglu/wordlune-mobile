# WordLune Firebase Architecture Documentation

## Overview
WordLune uses Firebase as its primary backend infrastructure, providing authentication, database, hosting, and analytics services. This document outlines the complete Firebase setup, configuration, and data architecture.

## Firebase Services Used

### 1. Firebase Authentication
- **Email/Password Authentication**: Primary authentication method
- **Google Sign-In**: Secondary authentication option
- **User Management**: Automatic user profile creation and session management

### 2. Cloud Firestore
- **NoSQL Database**: Primary data storage
- **Real-time Synchronization**: Live updates across clients
- **Security Rules**: Fine-grained access control
- **Offline Support**: Local caching and sync

### 3. Firebase Hosting
- **Static Site Hosting**: Next.js static export deployment
- **Custom Domain**: Support for custom domains
- **SSL Certificate**: Automatic HTTPS encryption
- **CDN**: Global content delivery network

### 4. Firebase Analytics
- **User Behavior Tracking**: Page views, user interactions
- **Custom Events**: Application-specific analytics
- **User Consent**: GDPR-compliant analytics initialization

## Environment Configuration

### Required Environment Variables
Create a `.env.local` file in the project root with the following variables:

```env
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key_here
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX
```

### Firebase SDK Configuration
Located in `src/lib/firebase.ts`:

```typescript
import { initializeApp, getApp, getApps } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getAnalytics, isSupported } from 'firebase/analytics';

// Exported services
export { app, auth, googleProvider, db, analytics };
```

## Database Architecture (Firestore)

### Collection Structure

#### `/users/{userId}`
User profile information:
```json
{
  "uid": "string",
  "displayName": "string", 
  "email": "string",
  "createdAt": "timestamp"
}
```

#### `/data/{userId}`
User's main data container:
```json
{
  "createdAt": "timestamp"
}
```

#### `/data/{userId}/loginHistory/{loginId}`
Login history tracking:
```json
{
  "timestamp": "timestamp",
  "userAgent": "string"
}
```

#### `/data/{userId}/{language}/lists/{listId}`
Word lists by language:
```json
{
  "name": "string",
  "description": "string",
  "isDefault": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### `/data/{userId}/{language}/lists/{listId}/words/{wordId}`
Words within lists:
```json
{
  "text": "string",
  "meaning": "string",
  "category": "Very Good | Good | Bad | Repeat | Uncategorized",
  "pronunciationText": "string",
  "exampleSentence": "string",
  "createdAt": "timestamp",
  "lastReviewedAt": "timestamp",
  "reviewCount": "number"
}
```

#### `/stories/{language}/stories/{storyId}`
Public stories:
```json
{
  "title": "string",
  "content": "string",
  "authorId": "string",
  "authorName": "string",
  "isPublished": "boolean",
  "language": "string",
  "difficulty": "Beginner | Intermediate | Advanced",
  "tags": ["array", "of", "strings"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "viewCount": "number",
  "likeCount": "number"
}
```

#### `/stories_by_author/{authorId}/stories/{storyId}`
Author's story management:
```json
{
  "storyId": "string",
  "language": "string",
  "title": "string",
  "isPublished": "boolean",
  "createdAt": "timestamp"
}
```

#### `/admins/{adminId}`
Admin user management:
```json
{
  "email": "string",
  "role": "admin",
  "permissions": ["array", "of", "permissions"],
  "createdAt": "timestamp"
}
```

#### `/versions/{versionId}`
App version and update information:
```json
{
  "version": "string",
  "releaseNotes": "string",
  "downloadUrl": "string",
  "forceUpdate": "boolean",
  "createdAt": "timestamp"
}
```

#### `/user_bans/{userId}`
User ban management:
```json
{
  "reason": "string",
  "bannedAt": "timestamp",
  "bannedBy": "string",
  "permanent": "boolean",
  "expiresAt": "timestamp"
}
```

## Security Rules

### Firestore Security Rules
Located in `firestore.rules`:

#### User Data Protection
- Users can only access their own data under `/data/{userId}`
- Strict user ID matching for all personal data operations

#### Story Access Control
- Public stories: Read access for published stories
- Author access: Full CRUD for own stories
- Draft protection: Only authors can read unpublished stories

#### Admin Protection
- Admin documents only readable by the admin themselves
- No client-side access to sensitive admin operations

#### Public Collections
- User profiles: Public read access, private write access
- App versions: Authenticated read access only

### Key Security Features
1. **User Isolation**: Each user's data is completely isolated
2. **Role-Based Access**: Different access levels for users, authors, admins
3. **Draft Protection**: Unpublished content remains private
4. **Authentication Required**: Most operations require valid authentication

## Authentication Flow

### Registration Process
1. **User Registration**: Email/password or Google sign-in
2. **Profile Creation**: Automatic user document creation
3. **Initial Setup**: Default data structure initialization
4. **Login History**: First login entry

### Login Process
1. **Credential Validation**: Firebase Auth verification
2. **Session Management**: Automatic token refresh
3. **User Context**: Loading user-specific data
4. **History Logging**: Login attempt tracking

### User Management Functions
Located in `src/lib/user-service.ts`:

#### `createInitialUserDocuments(userId, displayName, email)`
- Creates user profile document
- Initializes data container
- Sets up basic user structure

#### `logLoginHistory(userId)`
- Records login attempts
- Maintains login history (max 25 entries)
- Includes user agent information

## Hosting Configuration

### App Hosting Setup
Located in `apphosting.yaml`:

```yaml
runConfig:
  maxInstances: 1  # Adjust based on traffic needs
```

### Deployment Process
1. **Build Process**: Next.js static export
2. **Firebase Deploy**: Automatic deployment via GitHub Actions
3. **Domain Configuration**: Custom domain setup
4. **SSL Management**: Automatic certificate provisioning

## Development Workflow

### Local Development
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize project: `firebase init`
4. Start emulators: `firebase emulators:start`

### Firebase Emulator Suite
- **Authentication Emulator**: Local auth testing
- **Firestore Emulator**: Local database testing
- **Hosting Emulator**: Local hosting simulation

### Testing Strategy
1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Firebase service integration
3. **Security Rules Testing**: Rule validation
4. **End-to-End Tests**: Full application flow

## Performance Optimization

### Database Optimization
1. **Query Indexing**: Composite indexes for complex queries
2. **Data Pagination**: Limit results and implement pagination
3. **Offline Persistence**: Local caching for improved performance
4. **Batch Operations**: Minimize individual document operations

### Security Best Practices
1. **Least Privilege**: Minimal necessary permissions
2. **Input Validation**: Client and server-side validation
3. **Rate Limiting**: Prevent abuse and DoS attacks
4. **Regular Audits**: Security rule and access reviews

## Monitoring and Analytics

### Firebase Analytics
- **User Engagement**: Session duration, page views
- **Custom Events**: Feature usage tracking
- **Conversion Tracking**: Goal completion rates
- **User Demographics**: Geographic and device data

### Performance Monitoring
- **Load Times**: Page and function performance
- **Error Tracking**: Application error monitoring
- **Database Performance**: Query execution times
- **User Experience**: Core web vitals

## Backup and Recovery

### Data Backup Strategy
1. **Automatic Backups**: Firebase automatic daily backups
2. **Export Scripts**: Custom data export utilities
3. **Version Control**: Database rule versioning
4. **Disaster Recovery**: Multi-region backup strategy

### Data Migration
1. **Schema Changes**: Gradual migration scripts
2. **User Data Migration**: Preserve user data integrity
3. **Rollback Procedures**: Safe rollback mechanisms
4. **Testing Procedures**: Migration validation

## Cost Management

### Usage Optimization
1. **Read/Write Limits**: Efficient query patterns
2. **Storage Optimization**: Data structure efficiency
3. **Bandwidth Management**: Minimize unnecessary transfers
4. **Function Optimization**: Efficient serverless functions

### Monitoring Costs
- **Firebase Console**: Real-time usage monitoring
- **Billing Alerts**: Automated cost threshold alerts
- **Usage Analytics**: Identify cost optimization opportunities

## Troubleshooting

### Common Issues
1. **Authentication Errors**: Check environment variables
2. **Permission Denied**: Verify security rules
3. **Connection Issues**: Check network and Firebase status
4. **Data Sync Problems**: Clear cache and retry

### Debug Tools
1. **Firebase Console**: Real-time debugging
2. **Browser DevTools**: Network and console logging
3. **Firebase Emulators**: Local testing environment
4. **Security Rules Simulator**: Rule testing tool

## Migration from Username System

### Previous Architecture
The application previously used a username-based authentication system with the following structure:
- `/usernames/{username}` collection for username mapping
- Username fields in user documents
- Complex username validation and availability checking

### Current Simplified Architecture
**Migration completed** - removed username system in favor of email-only authentication:
- Eliminated `/usernames/` collection entirely
- Removed username fields from user documents
- Simplified authentication to email/password only
- Reduced complexity in user management functions

### Benefits of Email-Only System
1. **Simplified Registration**: No username availability checking required
2. **Reduced Complexity**: Fewer database operations and validations
3. **Better Security**: Direct email-based authentication
4. **Easier Maintenance**: Fewer edge cases and conflicts
5. **Standard Practice**: Follows common authentication patterns

This migration represents a significant architectural simplification that improves maintainability and user experience.
