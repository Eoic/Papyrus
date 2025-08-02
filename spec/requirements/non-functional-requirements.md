---
icon: head-side
layout:
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# Non-functional requirements

## 1. Storage

* NFR-1.1. Maximum allowed file size should not exceed 2048 MB per book file.
* NFR-1.2. The system should support the following storage methods:
  1. Local storage (on the device)
  2. Cloud storage: Google Drive, OneDrive, Dropbox
  3. Self-hosted server (MinIO, local file system)
  4. Network-attached storage (NAS)
* NFR-1.3. The system should support multiple storage backends per user with automatic failover.
* NFR-1.4. File encryption should be available for sensitive content with user-controlled keys.

## 2. Synchronization

* NFR-2.1. The system should work in online and offline mode with full feature parity.
* NFR-2.2. Any non-synchronized changes made offline should have an appropriate indicator.
* NFR-2.3. Synchronization conflicts should be resolved with user-selectable strategies (server wins, client wins, manual resolution).
* NFR-2.4. Cross-device synchronization should complete within 30 seconds under normal network conditions.

## 3. Platforms

* NFR-3.1. The system should be available in Firefox, Chrome, Safari, and Edge browsers.
* NFR-3.2. The system should be available on Windows 10 or later, macOS 10.15 or later, and major Linux distributions.
* NFR-3.3. The system should work on devices running Android 8.0 (API level 26) or later and iOS 12.0 or later.
* NFR-3.4. The system should support e-readers and tablets with touch interfaces.

## 4. Performance

* NFR-4.1. Application startup time should not exceed 3 seconds on supported devices.
* NFR-4.2. Book opening time should not exceed 2 seconds for files up to 50 MB.
* NFR-4.3. Search results should be returned within 1 second for libraries up to 10,000 books.
* NFR-4.4. The system should support libraries with up to 50,000 books without performance degradation.

## 5. Usability

* NFR-5.1. The user interface should follow Material 3 design guidelines.
* NFR-5.2. The application should be accessible to users with disabilities (WCAG 2.1 AA compliance).
* NFR-5.3. The system should support right-to-left (RTL) languages and internationalization.
* NFR-5.4. All user-facing text should be localizable with support for at least English as the primary language.

## 6. Security

* NFR-6.1. User passwords should be hashed using industry-standard algorithms (bcrypt, Argon2).
* NFR-6.2. All data transmission should use TLS 1.3 or higher encryption.
* NFR-6.3. The system should support two-factor authentication (TOTP).
* NFR-6.4. Session management should include automatic timeout and secure token handling.

## 7. Reliability

* NFR-7.1. The system should have 99.5% uptime for self-hosted deployments under normal conditions.
* NFR-7.2. Data corruption should be prevented through checksums and integrity verification.
* NFR-7.3. The system should gracefully handle network interruptions without data loss.
* NFR-7.4. Automatic backup and restore capabilities should be available for user data.
