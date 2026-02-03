# Papyrus Server

REST API server for Papyrus - a cross-platform book management application.

## Features

- User authentication (email/password and Google OAuth)
- Book management with metadata fetching
- Reading progress tracking
- Annotations, notes, and bookmarks
- Shelves, tags, and series organization
- Reading goals and statistics
- Cross-device synchronization
- Multiple storage backend support

## Requirements

- Python 3.12+
- PostgreSQL 15+

## Installation

```bash
# Install dependencies
pip install -e ".[dev]"

# Run the server
uvicorn papyrus.main:app --reload
```

## Development

```bash
# Run tests
pytest

# Run with coverage
pytest --cov

# Format code
ruff format .

# Lint code
ruff check .
```

## API Documentation

When the server is running, visit:

- OpenAPI UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>

## License

AGPL-3.0
