"""Authentication-related schemas."""

from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    """User registration request."""

    email: EmailStr = Field(..., examples=["user@example.com"])
    password: str = Field(..., min_length=8, examples=["SecureP@ss123"])
    display_name: str = Field(..., min_length=1, max_length=100, examples=["John Doe"])


class RegisterResponse(BaseModel):
    """User registration response."""

    user_id: UUID
    email: EmailStr
    message: str = Field(default="Account created. Please verify your email.")


class LoginRequest(BaseModel):
    """User login request."""

    email: EmailStr
    password: str


class GoogleOAuthRequest(BaseModel):
    """Google OAuth login request."""

    id_token: str = Field(..., description="Google OAuth ID token")


class RefreshTokenRequest(BaseModel):
    """Token refresh request."""

    refresh_token: str = Field(..., description="Refresh token from login")


class AuthTokens(BaseModel):
    """Authentication tokens response."""

    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = Field(..., description="Access token expiry in seconds", examples=[3600])
    user: "User | None" = None


class LogoutRequest(BaseModel):
    """Logout request."""

    all_devices: bool = Field(default=False, description="Logout from all devices")


class VerifyEmailRequest(BaseModel):
    """Email verification request."""

    token: str = Field(..., description="Email verification token")


class ForgotPasswordRequest(BaseModel):
    """Password recovery request."""

    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Password reset request."""

    token: str = Field(..., description="Password reset token")
    password: str = Field(..., min_length=8, description="New password")


class ChangePasswordRequest(BaseModel):
    """Password change request."""

    current_password: str
    new_password: str = Field(..., min_length=8)


# Import User here to avoid circular import
from papyrus.schemas.user import User  # noqa: E402

AuthTokens.model_rebuild()
