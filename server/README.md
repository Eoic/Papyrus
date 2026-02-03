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

## CI/CD

Quality checks run automatically on every push and pull request to the `server/` directory.

### Creating a release

The server uses independent versioning from the client with `server-v*` tags:

```bash
# Ensure you're on master with latest changes
git checkout master
git pull

# Create and push a version tag
git tag server-v1.0.0
git push origin server-v1.0.0
```

This triggers the release workflow which:

1. Runs all quality checks (format, lint, type check, tests)
2. Creates a GitHub Release with auto-generated release notes

## API Documentation

When the server is running, visit:

- OpenAPI UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>

## License

AGPL-3.0
