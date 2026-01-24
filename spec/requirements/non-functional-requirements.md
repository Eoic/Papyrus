# Non-Functional Requirements

This document defines the non-functional requirements (quality attributes) for Papyrus. These requirements specify how the system should perform rather than what it should do.

## Priority Levels

| Priority | Description | Target |
|----------|-------------|--------|
| **P0** | Critical - Must meet for MVP | v1.0 |
| **P1** | High - Should meet for MVP | v1.0 |
| **P2** | Medium - Post-MVP target | v1.x |
| **P3** | Low - Future enhancement | v2.x+ |

---

## 1. Storage

### NFR-1.1: Maximum File Size

**Priority:** P0

Maximum allowed file size shall not exceed 2048 MB (2 GB) per book file.

**Acceptance Criteria:**

- Files up to 2 GB upload successfully
- Files exceeding 2 GB are rejected with clear error message
- Large file uploads show progress indicator
- Upload can be resumed after interruption (for files > 100 MB)

### NFR-1.2: Storage Backend Support

**Priority:** P0

The system shall support multiple storage backends.

**Supported Backends:**

1. Local storage (device file system)
2. Cloud storage: Google Drive, OneDrive, Dropbox
3. Self-hosted server (MinIO, local file system)
4. Network-attached storage (NAS via SMB/NFS)

**Acceptance Criteria:**

- Each backend can be configured independently
- User can switch between backends without data loss
- Backend credentials are stored securely (encrypted)
- Connection status is visible to user

### NFR-1.3: Multi-Backend Configuration

**Priority:** P1

The system shall support multiple storage backends per user with automatic failover.

**Acceptance Criteria:**

- User can configure up to 3 storage backends
- One backend is designated as primary
- Automatic failover to secondary if primary is unavailable
- Manual override to force specific backend

### NFR-1.4: File Encryption

**Priority:** P2

File encryption shall be available for sensitive content with user-controlled keys.

**Acceptance Criteria:**

- AES-256 encryption for files at rest
- User-managed encryption keys
- Encrypted files are decrypted on-device only
- Key recovery mechanism available

---

## 2. Synchronization

### NFR-2.1: Online/Offline Parity

**Priority:** P0

The system shall work in online and offline mode with full feature parity for core reading features.

**Acceptance Criteria:**

- All reading features work offline
- Library management works offline
- Annotations and notes work offline
- Only sync and cloud features require connectivity
- Clear indicator of online/offline status

### NFR-2.2: Offline Change Indicators

**Priority:** P0

Any changes made offline shall have an appropriate visual indicator.

**Acceptance Criteria:**

- Unsynced items show sync-pending icon
- Last sync timestamp visible in settings
- Number of pending changes displayed
- User can manually trigger sync when online

### NFR-2.3: Conflict Resolution

**Priority:** P1

Synchronization conflicts shall be resolved with user-selectable strategies.

**Resolution Strategies:**

1. Server wins (default)
2. Client wins
3. Manual resolution (user chooses)
4. Merge (where possible)

**Acceptance Criteria:**

- User can set default strategy in settings
- Per-conflict override option
- Conflict history log
- No silent data loss

### NFR-2.4: Sync Performance

**Priority:** P0

Cross-device synchronization shall complete within 30 seconds under normal network conditions (>= 1 Mbps).

**Acceptance Criteria:**

- Reading position syncs within 30 seconds
- Metadata changes sync within 1 minute
- Book files sync based on file size and bandwidth
- Background sync does not impact reading performance

---

## 3. Platform Support

### NFR-3.1: Web Browser Support

**Priority:** P0

The system shall be available in modern web browsers.

**Supported Browsers:**

- Chrome 90+
- Firefox 90+
- Safari 14+
- Edge 90+

**Acceptance Criteria:**

- All core features work in supported browsers
- Progressive Web App (PWA) installable
- Offline capability via service worker
- Responsive design for all viewport sizes

### NFR-3.2: Desktop Operating System Support

**Priority:** P0

The system shall be available on major desktop operating systems.

**Supported Operating Systems:**

- Windows 10 or later
- macOS 10.15 (Catalina) or later
- Major Linux distributions (Ubuntu 20.04+, Fedora 35+, Debian 11+)

**Acceptance Criteria:**

- Native application available for each platform
- Platform-specific keyboard shortcuts
- System tray/menu bar integration
- File association for supported formats

### NFR-3.3: Mobile Operating System Support

**Priority:** P0

The system shall work on mobile devices.

**Supported Platforms:**

- Android 8.0 (API level 26) or later
- iOS 12.0 or later

**Acceptance Criteria:**

- App available in Google Play Store and Apple App Store
- Touch-optimized interface
- Support for device orientation changes
- Background sync support
- Push notifications (optional)

### NFR-3.4: E-ink Device Support

**Priority:** P1

The system shall support e-ink readers and tablets with touch interfaces.

**Target Devices:**

- Kobo readers (via sideloading)
- Android-based e-ink devices (Boox, Hisense)
- reMarkable (future consideration)

**Acceptance Criteria:**

- E-ink optimized UI mode (high contrast, grayscale)
- Reduced/disabled animations
- Larger touch targets (minimum 48px)
- Support for hardware page-turn buttons
- Reduced screen refresh for battery efficiency
- Dark-on-light and light-on-dark themes optimized for e-ink

---

## 4. Performance

### NFR-4.1: Application Startup

**Priority:** P0

Application startup time shall not exceed 3 seconds on supported devices.

**Acceptance Criteria:**

- Cold start < 3 seconds on mid-range devices (2020+)
- Warm start < 1 second
- Library view loads within 2 seconds of app start
- Progress indicator shown if startup exceeds 1 second

### NFR-4.2: Book Opening

**Priority:** P0

Book opening time shall not exceed 2 seconds for files up to 50 MB.

**Acceptance Criteria:**

- EPUB < 50 MB opens in < 2 seconds
- PDF < 50 MB opens in < 3 seconds
- Progress indicator for larger files
- Last reading position restored automatically
- Opening performance measured on mid-range devices

### NFR-4.3: Search Performance

**Priority:** P0

Search results shall be returned within 1 second for libraries up to 10,000 books.

**Acceptance Criteria:**

- Metadata search returns in < 500ms
- Full-text search returns in < 1 second
- Results are paginated for large result sets
- Search is cancelable
- Incremental results shown as available

### NFR-4.4: Library Scalability

**Priority:** P1

The system shall support libraries with up to 50,000 books without performance degradation.

**Acceptance Criteria:**

- Library view loads in < 3 seconds with 50,000 books
- Search remains under 2 seconds
- Scrolling remains smooth (60 FPS on capable devices)
- Memory usage scales linearly with library size
- Virtual scrolling for large lists

### NFR-4.5: E-ink Performance

**Priority:** P1

The system shall be optimized for e-ink display refresh characteristics.

**Acceptance Criteria:**

- Page turns complete in < 500ms
- Minimal full-refresh operations
- Partial refresh used where possible
- UI updates batched to reduce flicker
- Animation duration configurable (default: 0 for e-ink)

---

## 5. Usability

### NFR-5.1: Design System

**Priority:** P0

The user interface shall follow Material 3 design guidelines.

**Acceptance Criteria:**

- Consistent use of Material 3 components
- Dynamic color theming support
- Consistent typography scale
- Proper use of elevation and surfaces
- Dark/light theme support

### NFR-5.2: Accessibility

**Priority:** P0

The application shall be accessible to users with disabilities (WCAG 2.1 AA compliance).

**Acceptance Criteria:**

- Screen reader compatibility (TalkBack, VoiceOver)
- Minimum color contrast ratio 4.5:1
- All interactive elements keyboard accessible
- Focus indicators visible
- Text scalable up to 200%
- No information conveyed by color alone
- Touch targets minimum 44x44 points

### NFR-5.3: RTL and Internationalization

**Priority:** P1

The system shall support right-to-left (RTL) languages and internationalization.

**Acceptance Criteria:**

- UI mirrors correctly for RTL languages
- Book content renders correctly for RTL text
- Date/time formats localized
- Number formats localized
- Bidirectional text support

### NFR-5.4: Localization

**Priority:** P1

All user-facing text shall be localizable.

**Acceptance Criteria:**

- English as primary language
- Localization framework in place for additional languages
- No hardcoded user-facing strings
- Locale can be overridden in settings
- Pluralization rules supported

### NFR-5.5: E-ink Usability

**Priority:** P1

The system shall provide optimized usability for e-ink displays.

**Acceptance Criteria:**

- High contrast theme option
- Simplified UI with fewer visual elements
- Large, clear typography
- Reduced reliance on hover states
- Clear button/touch feedback without animations

---

## 6. Security

### NFR-6.1: Password Security

**Priority:** P0

User passwords shall be hashed using industry-standard algorithms.

**Acceptance Criteria:**

- Passwords hashed with bcrypt or Argon2
- Minimum password length: 8 characters
- Password strength indicator during registration
- No plaintext password storage or transmission
- Secure password reset mechanism

### NFR-6.2: Transport Security

**Priority:** P0

All data transmission shall use TLS 1.3 or higher encryption.

**Acceptance Criteria:**

- HTTPS required for all API communication
- Certificate pinning for mobile apps (optional)
- No fallback to unencrypted connections
- TLS 1.2 minimum (1.3 preferred)

### NFR-6.3: Two-Factor Authentication

**Priority:** P2

The system shall support two-factor authentication (TOTP).

**Acceptance Criteria:**

- TOTP-based 2FA (Google Authenticator compatible)
- Backup codes available
- 2FA can be enabled/disabled by user
- Graceful recovery if 2FA device lost

### NFR-6.4: Session Management

**Priority:** P0

Session management shall include automatic timeout and secure token handling.

**Acceptance Criteria:**

- JWT tokens with configurable expiration
- Refresh token rotation
- Sessions can be revoked remotely
- Automatic logout after inactivity (configurable)
- Secure token storage on device

### NFR-6.5: Privacy by Default

**Priority:** P0

The application shall collect no analytics by default; telemetry is opt-in.

**Acceptance Criteria:**

- No analytics without explicit consent
- Clear privacy policy accessible in-app
- Telemetry settings easily accessible
- No third-party tracking SDKs by default
- Data collection scope clearly explained

---

## 7. Reliability

### NFR-7.1: System Uptime

**Priority:** P1

The system shall have 99.5% uptime for self-hosted deployments under normal conditions.

**Acceptance Criteria:**

- Maximum planned downtime: 4 hours/month
- Health check endpoints available
- Graceful degradation during partial outages
- Automatic recovery from transient failures

### NFR-7.2: Data Integrity

**Priority:** P0

Data corruption shall be prevented through checksums and integrity verification.

**Acceptance Criteria:**

- File checksums verified on upload/download
- Database transactions are atomic
- Corrupted files detected and reported
- No silent data corruption

### NFR-7.3: Network Resilience

**Priority:** P0

The system shall gracefully handle network interruptions without data loss.

**Acceptance Criteria:**

- Operations are idempotent where possible
- Uploads/downloads resumable
- No data loss on network failure
- Clear error messages for network issues
- Automatic retry with exponential backoff

### NFR-7.4: Backup and Restore

**Priority:** P1

Automatic backup and restore capabilities shall be available for user data.

**Acceptance Criteria:**

- Export all user data in portable format
- Import/restore from backup
- Scheduled automatic backups (optional)
- Backup integrity verification

---

## 8. Extensibility

### NFR-8.1: Plugin Architecture

**Priority:** P3

The architecture shall support modular plugins without compromising core stability.

**Acceptance Criteria:**

- Plugin API documented
- Plugins run in sandboxed environment
- Core functionality unaffected by plugin failures
- Plugin enable/disable without restart
- Version compatibility checking

---

## 9. Maintainability

### NFR-9.1: Code Quality

**Priority:** P1

The codebase shall maintain high quality standards.

**Acceptance Criteria:**

- Automated linting (dart analyze)
- Code formatting enforced (dart format)
- Minimum 70% test coverage for core functionality
- No critical security vulnerabilities
- Documentation for public APIs

### NFR-9.2: Logging and Monitoring

**Priority:** P1

The system shall provide comprehensive logging and monitoring capabilities.

**Acceptance Criteria:**

- Structured logging for all components
- Log levels configurable (debug, info, warning, error)
- No sensitive data in logs
- Log rotation and retention policies
- Error tracking integration (optional)

---

## Requirements Summary

### MVP (P0/P1) Requirements Count

| Category | P0 | P1 | Total |
|----------|----|----|-------|
| Storage | 2 | 1 | 3 |
| Synchronization | 3 | 1 | 4 |
| Platforms | 3 | 1 | 4 |
| Performance | 3 | 2 | 5 |
| Usability | 2 | 3 | 5 |
| Security | 3 | 0 | 3 |
| Reliability | 1 | 2 | 3 |
| Extensibility | 0 | 0 | 0 |
| Maintainability | 0 | 2 | 2 |
| **Total** | **17** | **12** | **29** |

### Post-MVP (P2/P3) Requirements

| Requirement | Priority | Description |
|-------------|----------|-------------|
| NFR-1.4 | P2 | File Encryption |
| NFR-6.3 | P2 | Two-Factor Authentication |
| NFR-8.1 | P3 | Plugin Architecture |
