---
description: Graphical representation of the database structure.
---

# Database model

This section presents the database schema design for the system, showing the relationships between entities and their attributes. The model is designed to support cross-platform synchronization, flexible storage options, and comprehensive book management features.

## Database schema overview

The database consists of several interconnected tables that support the core functionality:

- **User management**: User accounts with support for anonymous, email/password, and OAuth authentication
- **Book management**: Flexible book storage with metadata, physical/digital distinction, and file handling
- **Organization**: Shelves and tags for book categorization
- **Reading experience**: Annotations, notes, reading sessions, and customizable profiles
- **Goal tracking**: Reading goals and progress monitoring
- **Storage configuration**: Multiple storage backend support

## Entity relationship diagram

```mermaid
erDiagram
    USER {
        uuid user_id PK
        string email UK
        string password_hash
        string display_name
        string google_id UK
        boolean is_anonymous
        timestamp created_at
        timestamp updated_at
        timestamp last_login_at
        boolean is_active
    }
    
    BOOK {
        uuid book_id PK
        uuid user_id FK
        string title
        string subtitle
        string author
        json co_authors
        string isbn
        string isbn13
        date publication_date
        string publisher
        string language
        integer page_count
        text description
        string cover_image_url
        string file_path
        string file_format
        bigint file_size
        boolean is_physical
        boolean is_favorite
        integer rating
        string reading_status
        integer current_page
        decimal current_position
        timestamp added_at
        timestamp last_read_at
        json metadata
        boolean is_ocr_processed
        decimal ocr_confidence
    }
    
    SHELF {
        uuid shelf_id PK
        uuid user_id FK
        string name
        text description
        string color
        boolean is_default
        integer sort_order
        timestamp created_at
        timestamp updated_at
    }
    
    TAG {
        uuid tag_id PK
        uuid user_id FK
        string name
        string color
        text description
        timestamp created_at
    }
    
    ANNOTATION {
        uuid annotation_id PK
        uuid book_id FK
        uuid user_id FK
        text selected_text
        text note
        string highlight_color
        string start_position
        string end_position
        string chapter_title
        integer page_number
        timestamp created_at
        timestamp updated_at
    }
    
    NOTE {
        uuid note_id PK
        uuid book_id FK
        uuid user_id FK
        string title
        text content
        boolean is_private
        timestamp created_at
        timestamp updated_at
    }
    
    READING_SESSION {
        uuid session_id PK
        uuid book_id FK
        uuid user_id FK
        timestamp start_time
        timestamp end_time
        decimal start_position
        decimal end_position
        integer pages_read
        integer duration_minutes
        string device_type
        timestamp created_at
    }
    
    READING_GOAL {
        uuid goal_id PK
        uuid user_id FK
        string title
        text description
        string goal_type
        integer target_value
        integer current_value
        string time_period
        date start_date
        date end_date
        boolean is_active
        boolean is_completed
        timestamp completed_at
        timestamp created_at
        timestamp updated_at
    }
    
    READING_PROFILE {
        uuid profile_id PK
        uuid user_id FK
        string name
        boolean is_default
        string font_family
        integer font_size
        decimal line_height
        decimal letter_spacing
        decimal paragraph_spacing
        integer margin_horizontal
        integer margin_vertical
        string background_color
        string text_color
        string link_color
        string selection_color
        string theme_mode
        boolean page_turn_animation
        string reading_mode
        integer column_count
        boolean justification
        boolean hyphenation
        timestamp created_at
        timestamp updated_at
    }
    
    STORAGE_CONFIG {
        uuid config_id PK
        uuid user_id FK
        string storage_type
        boolean is_primary
        boolean is_active
        text connection_string
        text credentials
        string base_path
        boolean sync_enabled
        timestamp last_sync_at
        timestamp created_at
        timestamp updated_at
    }
    
    BOOK_SHELF {
        uuid book_id FK
        uuid shelf_id FK
        timestamp added_at
    }
    
    BOOK_TAG {
        uuid book_id FK
        uuid tag_id FK
        timestamp created_at
    }

    USER ||--o{ BOOK : owns
    USER ||--o{ SHELF : creates
    USER ||--o{ TAG : creates
    USER ||--o{ ANNOTATION : makes
    USER ||--o{ NOTE : writes
    USER ||--o{ READING_SESSION : has
    USER ||--o{ READING_GOAL : sets
    USER ||--o{ READING_PROFILE : configures
    USER ||--o{ STORAGE_CONFIG : manages
    
    BOOK ||--o{ ANNOTATION : contains
    BOOK ||--o{ NOTE : has
    BOOK ||--o{ READING_SESSION : tracked_in
    
    BOOK }o--o{ SHELF : organized_in
    BOOK }o--o{ TAG : tagged_with
    
    BOOK_SHELF }o--|| BOOK : references
    BOOK_SHELF }o--|| SHELF : references
    
    BOOK_TAG }o--|| BOOK : references
    BOOK_TAG }o--|| TAG : references
```

## Key design principles

### Data integrity
- **Foreign key constraints**: Ensure referential integrity across all relationships
- **Unique constraints**: Prevent duplicate user emails, shelf names per user, etc.
- **Check constraints**: Validate data ranges (ratings 1-5, positions 0-1, etc.)
- **NOT NULL constraints**: Ensure required fields are always populated

### Performance optimization
- **Primary indexes**: UUID primary keys with automatic indexing
- **Foreign key indexes**: Automatic indexing on all foreign key relationships
- **Search indexes**: Full-text search capabilities on book content and metadata
- **Composite indexes**: Multi-column indexes for common query patterns

### Scalability considerations
- **UUID identifiers**: Support for distributed systems and data migration
- **JSON fields**: Flexible metadata storage without schema changes
- **Nullable fields**: Support for incomplete data and gradual data entry
- **Audit fields**: Created/updated timestamps for all entities

### Data types and constraints

**Common patterns:**
- **Primary Keys**: UUID for global uniqueness and distribution support
- **Timestamps**: With timezone support for global user base
- **Text fields**: Varying lengths based on expected content size
- **Boolean flags**: Clear true/false states with appropriate defaults
- **JSON fields**: Flexible storage for metadata and configuration

**Validation rules:**
- Email addresses must be unique across users
- Book ratings must be between 1 and 5
- Reading positions must be between 0.0 and 1.0
- Goal target values must be positive integers
- Font sizes must be within reasonable ranges (8-72)

### Migration strategy

The database schema is designed to support incremental updates and migrations:

- **Version tracking**: Schema version table for migration management
- **Backward compatibility**: New fields are nullable to support gradual rollouts
- **Index management**: Indexes can be added/removed without data loss
- **Data preservation**: Migration scripts preserve existing user data

This database model provides a robust foundation for the system while maintaining flexibility for future enhancements and ensuring data integrity across all operations.

