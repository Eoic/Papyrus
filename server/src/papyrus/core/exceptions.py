"""Custom exception classes for the application."""

from typing import Any


class AppError(Exception):
    """Base application error."""

    def __init__(
        self,
        message: str,
        code: str = "INTERNAL_ERROR",
        status_code: int = 500,
        details: dict[str, Any] | None = None,
    ) -> None:
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


class NotFoundError(AppError):
    """Resource not found."""

    def __init__(
        self, message: str = "Resource not found", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(message=message, code="NOT_FOUND", status_code=404, details=details)


class ValidationError(AppError):
    """Validation error."""

    def __init__(
        self, message: str = "Validation error", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(message=message, code="VALIDATION_ERROR", status_code=400, details=details)


class UnauthorizedError(AppError):
    """Authentication required."""

    def __init__(
        self, message: str = "Authentication required", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(message=message, code="UNAUTHORIZED", status_code=401, details=details)


class ForbiddenError(AppError):
    """Access denied."""

    def __init__(
        self, message: str = "Access denied", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(message=message, code="FORBIDDEN", status_code=403, details=details)


class ConflictError(AppError):
    """Resource conflict."""

    def __init__(
        self, message: str = "Resource already exists", details: dict[str, Any] | None = None
    ) -> None:
        super().__init__(message=message, code="CONFLICT", status_code=409, details=details)


class RateLimitError(AppError):
    """Rate limit exceeded."""

    def __init__(
        self,
        message: str = "Too many requests",
        retry_after: int = 60,
        details: dict[str, Any] | None = None,
    ) -> None:
        details = details or {}
        details["retry_after"] = retry_after
        super().__init__(
            message=message, code="RATE_LIMIT_EXCEEDED", status_code=429, details=details
        )
