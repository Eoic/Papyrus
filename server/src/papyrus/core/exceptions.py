"""Custom exception classes for the application."""

from typing import Any


class AppException(Exception):
    """Base application exception."""

    def __init__(
        self,
        message: str,
        code: str = "INTERNAL_ERROR",
        details: dict[str, Any] | None = None,
    ) -> None:
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(message)


class NotFoundError(AppException):
    """Resource not found."""

    def __init__(self, message: str = "Resource not found", details: dict[str, Any] | None = None) -> None:
        super().__init__(message=message, code="NOT_FOUND", details=details)


class ValidationError(AppException):
    """Validation error."""

    def __init__(self, message: str = "Validation error", details: dict[str, Any] | None = None) -> None:
        super().__init__(message=message, code="VALIDATION_ERROR", details=details)


class UnauthorizedError(AppException):
    """Authentication required."""

    def __init__(self, message: str = "Authentication required", details: dict[str, Any] | None = None) -> None:
        super().__init__(message=message, code="UNAUTHORIZED", details=details)


class ForbiddenError(AppException):
    """Access denied."""

    def __init__(self, message: str = "Access denied", details: dict[str, Any] | None = None) -> None:
        super().__init__(message=message, code="FORBIDDEN", details=details)


class ConflictError(AppException):
    """Resource conflict."""

    def __init__(self, message: str = "Resource already exists", details: dict[str, Any] | None = None) -> None:
        super().__init__(message=message, code="CONFLICT", details=details)


class RateLimitError(AppException):
    """Rate limit exceeded."""

    def __init__(
        self,
        message: str = "Too many requests",
        retry_after: int = 60,
        details: dict[str, Any] | None = None,
    ) -> None:
        details = details or {}
        details["retry_after"] = retry_after
        super().__init__(message=message, code="RATE_LIMIT_EXCEEDED", details=details)
