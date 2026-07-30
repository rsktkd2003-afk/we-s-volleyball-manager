# We's Volleyball Manager

> Bring the team together and make it easier to keep practicing.

We's Volleyball Manager is a Flutter and Firebase application built to support the day-to-day operation of a volleyball team. It centralizes player information, schedules, attendance, team notices, goals, and match planning in one shared application.

The project was created from real team-management needs, including missed schedule updates, unclear attendance counts, and information being scattered across chat messages.

[Open the web application](https://we-s-volleyball-manager.web.app)

> The current user interface is primarily in Japanese. The application is designed for one shared team and does not use `teamId`-based multi-team isolation.

## Features

### Authentication and membership

- Register and sign in with an email address and password.
- Maintain a display name and account profile.
- Use `member` and `admin` roles.
- Link a user account to an existing player through an administrator-approved request.
- Sign out while removing the current device's stored notification token where possible.

### Player management

- Create and maintain player profiles.
- Store jersey number, position, grade, dominant hand, physical measurements, and volleyball skill ratings.
- Search, filter, and sort the player list.
- View and edit player details.
- Record player-specific issues and comments.

### Schedule and attendance

- View team schedules in a responsive monthly calendar.
- Create and edit practices, matches, and other events.
- Create repeated schedules and reusable schedule templates.
- Record attendance responses, including participation, lateness, absence, and an undecided late-arrival time.
- View schedules and attendance updates through Firestore real-time synchronization.

### Team communication and planning

- Post shared announcements.
- Maintain monthly team goals.
- Create match-date polls and collect one vote per signed-in user.
- Confirm or close match polls through the supported administrator flow.
- Review pending player-link requests from the notification center.

### Device notifications

- Enable or disable notifications per device.
- Register Firebase Cloud Messaging tokens under the signed-in user's account.
- Remove or replace stale device tokens during sign-out, account changes, and token refreshes.
- Disable the web notification setting safely when no Web Push VAPID public key is configured.

## Technology Stack

| Area | Technology |
|---|---|
| Application | Flutter, Dart, Material 3 |
| State management | Riverpod |
| Authentication | Firebase Authentication |
| Database and real-time updates | Cloud Firestore |
| Device notifications | Firebase Cloud Messaging |
| Calendar | Syncfusion Flutter Calendar |
| Web hosting | Firebase Hosting |

## Primary Platforms

- Web
- Android
- Windows

Firebase client configuration also exists for additional Flutter targets, but the platforms above are the primary documented targets for this project.

## Firestore Data Model

The current implementation uses a single-team shared data model. The main collections and subcollections are:

| Path | Purpose |
|---|---|
| `users` | Account profile, role, and linked player |
| `users/{uid}/fcmTokens` | Per-device Firebase Cloud Messaging tokens |
| `players` | Player profiles and volleyball data |
| `players/{playerId}/issues` | Player-specific issues |
| `players/{playerId}/issues/{issueId}/comments` | Issue comments |
| `player_link_requests` | Requests to link an account to a player |
| `schedules` | Practices, matches, and other team events |
| `schedules/{scheduleId}/responses` | Per-user attendance responses |
| `schedule_templates` | Reusable schedule templates |
| `announcements` | Shared team notices |
| `goals` | Team goals |
| `match_polls` | Match-date polls |
| `match_polls/{pollId}/votes` | Per-user poll votes |

The app intentionally does not read or write `teamId`. Supporting multiple independent teams would require a separate data-isolation design and revised Firestore Security Rules.

## Requirements

- Flutter SDK compatible with Dart `^3.12.1`
- A supported browser, Android development environment, or Windows desktop toolchain
- Firebase CLI for Firebase Hosting or Firestore Rules deployment
- A Firebase project when using a development environment separate from the configured project

## Local Setup

### Windows PowerShell

```powershell
git clone https://github.com/rsktkd2003-afk/we-s-volleyball-manager.git
Set-Location we-s-volleyball-manager
flutter pub get
flutter run -d chrome
```

### macOS or Linux

```bash
git clone https://github.com/rsktkd2003-afk/we-s-volleyball-manager.git
cd we-s-volleyball-manager
flutter pub get
flutter run -d chrome
```

The repository contains generated Firebase client configuration. Unless you replace that configuration or use Firebase emulators, a local build may connect to the configured Firebase project. Do not use production data for development tests.

## Common Commands

```powershell
flutter pub get
flutter analyze
flutter build web
flutter build apk
flutter build windows
```

Run only the build commands supported by the current development machine.

## Web Notification Configuration

Web notifications require a Web Push VAPID public key at compile time:

```powershell
flutter run -d chrome --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

For a production web build:

```powershell
flutter build web --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Only the public VAPID key belongs in the client build. Never include a private VAPID key, Firebase Admin credential, service-account file, or FCM server credential in the application.

## Web Deployment

Confirm the target Firebase project before deployment, then run:

```powershell
flutter pub get
flutter analyze
flutter build web
firebase deploy --only hosting
```

Deployment is intentionally separate from merging a pull request.

## Security and Privacy Notes

- The app stores account information, player data, schedules, attendance, messages, goals, polls, and notification tokens in Firebase.
- Shared team data is available according to the repository's Firestore Security Rules; client-side screens are not an authorization boundary.
- The current data model is for one team and must not be treated as secure multi-tenant isolation.
- Player measurements, availability, comments, and account information should be treated as personal data.
- Avoid storing medical details or other high-risk sensitive information unless an appropriate policy, access model, and retention process are established.

See [SECURITY.md](SECURITY.md) for the current access-control model, reporting process, and known security gaps.

## Current Limitations

- The application is not designed for multiple independent teams.
- Notification availability depends on the target platform, user permission, and Firebase project configuration.
- Automated test coverage is currently limited; pull-request checks focus on static analysis and the web build.
- Firebase console settings and the rules currently deployed to Firebase must be verified separately from the repository.

## Development Workflow

See [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) for the branch, review, validation, merge, and deployment process.

Before opening a pull request, run:

```powershell
flutter pub get
flutter analyze
flutter build web
```

Do not commit service-account credentials, private keys, real user exports, FCM tokens, or screenshots containing personal team information.
