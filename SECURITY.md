# Security Policy

Last updated: July 31, 2026

## Supported Versions

Security fixes are applied to the latest code on the `main` branch and, when applicable, to the current Firebase Hosting deployment. Older commits, local builds, and superseded deployments may not receive security updates.

## Reporting a Vulnerability

Do not disclose a vulnerability through a public issue, pull request, discussion, screenshot, or log if the report contains exploit details, credentials, Firebase tokens, personal information, player data, attendance data, or private team content.

Use GitHub's private vulnerability reporting option if it is available for this repository. Otherwise, contact the repository owner through a private channel. If no private channel is available, open a minimal public issue asking how to submit a private security report without including technical details.

A useful report includes:

- The affected URL, platform, branch, commit, or application version.
- The affected component, such as Firebase Authentication, Firestore Rules, player linking, schedules, attendance, or FCM token handling.
- Reproduction steps using only accounts and data that you are authorized to test.
- The security or privacy impact.
- Sanitized evidence that contains no credentials or personal team information.
- A suggested mitigation, if known.

This is a personal project and does not currently provide a guaranteed response or resolution time. Reports will be assessed and fixes will be coordinated privately when possible.

## Security Scope

Examples of issues that are in scope include:

- Authentication bypass, account takeover, or unsafe session handling.
- Unauthorized role changes or administrator privilege escalation.
- Unauthorized access to user profiles, player data, schedules, attendance, announcements, goals, polls, issues, or comments.
- Bypassing the player-link approval process.
- Reading, writing, retaining, or associating an FCM token with the wrong account.
- Cross-site scripting or unsafe content handling in the web application.
- Exposure of service-account files, private keys, access tokens, FCM server credentials, or private VAPID keys.
- Dependency or build-chain vulnerabilities that are exploitable in the application.

General UI defects and feature requests should be reported as normal issues unless they also create a security or privacy impact.

## Security Model

### Single-team design

The current application uses one shared Firestore dataset for one volleyball team. It does not use `teamId` and does not provide tenant isolation between multiple teams.

This design must not be reused for unrelated teams without a new authorization model, migrated document paths, and revised Firestore Security Rules.

### Authentication and account creation

- Firebase Authentication provides email-and-password registration and sign-in.
- A newly created Firestore user document receives the `member` role and no linked player.
- A member without a linked player is directed to the player-link request screen.
- Administrators can approve or reject player-link requests.
- Client-side navigation is not an authorization boundary. Firestore Security Rules must protect every read and write independently.

### Role handling

The administrator role is read from `users/{uid}.role`. The current rules prevent a normal user from changing their own role or linked player through the allowed self-update path. Administrator privileges therefore depend on protecting the user document and the Firebase project administration environment.

## Current Firestore Access Controls

The summaries below describe the repository's current `firestore.rules`. The rules actually deployed to Firebase must be verified separately.

| Data | Current rule summary |
|---|---|
| `users` | Any signed-in user can read user documents. A user can create their own member document and update a limited set of their own profile fields. Administrators can update or delete user documents. |
| `users/{uid}/fcmTokens` | Reads are denied. A signed-in user can create, update, or delete tokens only under their own UID. |
| `players` | Any signed-in user can read players. A signed-in user can create a player only with `linkedUid == null`. Updates are allowed to administrators or when `linkedUid` remains unchanged. Deletion is allowed to administrators or the stored `ownerUid`. |
| Player issues and comments | Any signed-in user can read them. Creation records the authenticated creator. Updates are limited to the creator or an administrator while protected creator fields remain unchanged. Deletion is denied. |
| `player_link_requests` | Administrators can read requests; a user can read their own request. Users can create a constrained pending request for themselves, and administrators can approve or reject pending requests. |
| `announcements` and `goals` | Any signed-in user can read and create them. Updates and deletion are limited to the creator or an administrator while creator fields remain unchanged. |
| `match_polls` | Any signed-in user can read and create an open poll. Supported state changes are constrained by status, creator, and administrator checks. Direct deletion is denied. |
| Poll votes | Any signed-in user can read votes. A user can create or update only the vote document whose ID and stored UID match their own UID while the poll is open. |
| `schedules` | Any signed-in user can read and create schedules. Creation must record the authenticated creator. Any signed-in user can currently update a schedule. Deletion is limited to the creator or an administrator. |
| Schedule responses | Any signed-in user can read responses. A user can write only the response document matching their UID; administrators can manage all responses. |
| `schedule_templates` | Any signed-in user can read, create, or update templates. Only administrators can delete them. |

## Data Handled by the Application

Depending on use, Firebase may store:

- Email address, display name, UID, role, and linked player ID.
- Player profile information, physical measurements, skill ratings, issues, and comments.
- Event titles, locations, dates, attendance responses, and late-arrival information.
- Announcements, monthly goals, match polls, and votes.
- Per-device FCM registration tokens and platform information.

This data should be treated as private team information. Do not use real personal data in public issues, test fixtures, screenshots, or pull-request descriptions.

## Firebase and Secret Handling

- Generated Firebase client configuration identifies the Firebase project but is not a server-side authorization secret.
- Security must rely on Firebase Authentication, Firestore Security Rules, authorized-domain configuration, and appropriate Firebase project administration.
- Service-account JSON files, Firebase Admin credentials, private keys, access tokens, FCM server credentials, and private VAPID keys must never be committed or embedded in the Flutter application.
- `FCM_WEB_VAPID_KEY` is intended only for the Web Push public key supplied at build time. The corresponding private key must remain server-side.
- If a real secret is exposed, revoke or rotate it immediately and remove it from all reachable Git history, build systems, and deployment environments.

## Notification Token Protection

- FCM token documents are stored below the current user's UID.
- Firestore Rules deny client reads of the token subcollection.
- Token mutations are serialized to reduce account-switching races.
- The application invalidates the previous notification session and attempts to remove the current token when notifications are disabled or the user signs out.
- Notification cleanup is best effort and must not be treated as proof that every stale server-side token has been removed.

## Developer Security Checklist

Before release, run:

```powershell
flutter pub get
flutter analyze
flutter build web
```

When Authentication, Firestore paths, roles, player linking, attendance, or notification handling changes, also verify:

- An unauthenticated client cannot read or write protected Firestore data.
- A member cannot change their own `role` or `playerId`.
- A user cannot read or modify another user's FCM token documents.
- A player-link request cannot be approved or rejected by a normal member.
- A user cannot submit an attendance response under another user's UID.
- Poll votes cannot be written under another user's UID.
- Creator fields cannot be replaced during updates where they are protected.
- Signing out does not leave the next signed-in account associated with the previous account's notification token.

Use the Firebase Emulator Suite with synthetic accounts and data before deploying rule changes. Verify the active Firebase project before deploying:

```powershell
firebase use
firebase emulators:start --only firestore
```

Do not deploy Authentication settings, Firestore Rules, indexes, Functions, or Hosting as part of an unrelated change.

## Responsible Testing

- Test only accounts, Firebase projects, devices, and data that you own or are explicitly authorized to use.
- Do not access, modify, retain, or disclose another member's information.
- Stop testing if you encounter unexpected personal data.
- Do not perform denial-of-service testing against the public deployment.
- Allow reasonable time for assessment and remediation before public disclosure.

## Known Security Gaps

The following limitations are present or not yet confirmed as resolved:

- Many shared collections can be read by any authenticated Firebase account. Player-link approval is a user-interface gate and is not currently a general Firestore read-authorization requirement.
- All signed-in users can currently update schedules.
- Signed-in users have broad create or update permissions for players and schedule templates.
- User documents are readable by all signed-in users and may contain email addresses and display names.
- The data model has no multi-team isolation.
- Automated Firestore Rules tests are not confirmed.
- Firebase App Check enforcement is not confirmed.
- The rules and Firebase settings currently deployed to production have not been verified against the repository in this review.
- Self-service password recovery, email verification, account deletion, and full personal-data deletion are not confirmed.
- A dedicated security contact address is not configured.

These limitations should be addressed before public onboarding is expanded, multiple teams are supported, or higher-risk personal information is stored.
