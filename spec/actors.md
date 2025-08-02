---
description: This section lists user groups which will interact with the system.
---

# Actors

The system is designed to serve different types of users with varying needs and technical expertise levels. The following actors represent the main user groups that will interact with the system:

## Primary actors

### Reader
The core user of the system who primarily uses the application for reading and managing books.

**Characteristics:**
- Regular book consumer (physical and/or digital books)
- Uses multiple devices (smartphone, tablet, desktop, e-reader)
- Values seamless reading experience across platforms
- May have varying technical expertise levels

**Goals:**
- Read books comfortably on preferred devices
- Organize and manage book collections
- Track reading progress and habits
- Synchronize data across devices
- Maintain personal reading goals

**Interactions:**
- Import and organize books into libraries
- Read books using the integrated viewer
- Create notes and annotations
- Set and track reading goals
- Customize reading experience and preferences

### Anonymous user
A user who accesses the system without creating an account, using the application in offline mode.

**Characteristics:**
- Privacy-conscious individuals
- Users who want to try the application before committing
- Users in areas with limited internet connectivity
- May later convert to registered users

**Goals:**
- Use core reading functionality without registration
- Maintain privacy and data control
- Access application without internet dependency

**Interactions:**
- Import and read books locally
- Use basic library management features
- Access offline functionality
- Optionally migrate to registered account later

### Registered user
A user who has created an account and can access synchronization and cloud features.

**Characteristics:**
- Users who want cross-device synchronization
- Users with multiple reading devices
- Users who value backup and recovery options
- May use self-hosted or cloud storage solutions

**Goals:**
- Synchronize data across multiple devices
- Back up reading data and preferences
- Access books from anywhere
- Share reading progress between devices

**Interactions:**
- All Reader capabilities
- Account management (login, password recovery)
- Configure synchronization settings
- Manage storage preferences
- Access cloud-based features

## Secondary actors

### System administrator
Technical user responsible for maintaining self-hosted Papyrus server instances.

**Characteristics:**
- Technical expertise in server administration
- Manages Papyrus installations for organizations or personal use
- Responsible for data security and system maintenance

**Goals:**
- Deploy and maintain Papyrus server instances
- Ensure system security and data protection
- Monitor system performance and usage
- Manage user accounts and permissions

**Interactions:**
- Server installation and configuration
- User management and authentication setup
- Storage backend configuration
- System monitoring and maintenance
- Security updates and patches

### Developer
Technical user who integrates with or extends the system.

**Characteristics:**
- Software developers and integrators
- Technical users building custom solutions
- Third-party service providers

**Goals:**
- Integrate with Papyrus API
- Build custom front-ends or extensions
- Develop complementary tools and services

**Interactions:**
- REST API usage
- Custom client development
- Data export and import
- System integration projects

