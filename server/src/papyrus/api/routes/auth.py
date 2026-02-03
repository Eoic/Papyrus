"""Authentication routes."""

from uuid import uuid4

from fastapi import APIRouter, Response, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import (
    AuthTokens,
    GoogleOAuthRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    RegisterResponse,
    User,
)
from papyrus.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LogoutRequest,
    ResetPasswordRequest,
    VerifyEmailRequest,
)
from papyrus.schemas.common import MessageResponse

router = APIRouter()


@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
async def register_user(request: RegisterRequest) -> RegisterResponse:
    """Create a new user account with email and password."""
    return RegisterResponse(
        user_id=uuid4(),
        email=request.email,
        message="Account created. Please verify your email.",
    )


@router.post(
    "/login",
    response_model=AuthTokens,
    summary="Login with email and password",
)
async def login_user(request: LoginRequest) -> AuthTokens:
    """Authenticate a user with email and password credentials."""
    from datetime import UTC, datetime

    return AuthTokens(
        access_token="example_access_token",
        refresh_token="example_refresh_token",
        token_type="Bearer",
        expires_in=3600,
        user=User(
            user_id=uuid4(),
            email=request.email,
            display_name="Example User",
            is_anonymous=False,
            email_verified=True,
            created_at=datetime.now(UTC),
        ),
    )


@router.post(
    "/oauth/google",
    response_model=AuthTokens,
    summary="Login or register with Google OAuth",
)
async def google_oauth(request: GoogleOAuthRequest) -> AuthTokens:
    """Authenticate a user via Google OAuth 2.0."""
    from datetime import UTC, datetime

    return AuthTokens(
        access_token="example_google_access_token",
        refresh_token="example_google_refresh_token",
        token_type="Bearer",
        expires_in=3600,
        user=User(
            user_id=uuid4(),
            email="google_user@example.com",
            display_name="Google User",
            is_anonymous=False,
            email_verified=True,
            created_at=datetime.now(UTC),
        ),
    )


@router.post(
    "/refresh",
    response_model=AuthTokens,
    summary="Refresh access token",
)
async def refresh_token(request: RefreshTokenRequest) -> AuthTokens:
    """Exchange a valid refresh token for a new access token."""
    return AuthTokens(
        access_token="new_access_token",
        refresh_token="new_refresh_token",
        token_type="Bearer",
        expires_in=3600,
    )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Logout and invalidate tokens",
)
async def logout_user(
    user_id: CurrentUserId,
    request: LogoutRequest | None = None,
) -> Response:
    """Invalidate the current session and all associated tokens."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/verify-email",
    response_model=MessageResponse,
    summary="Verify email address",
)
async def verify_email(request: VerifyEmailRequest) -> MessageResponse:
    """Verify the user's email address using the token sent via email."""
    return MessageResponse(message="Email verified successfully")


@router.post(
    "/resend-verification",
    response_model=MessageResponse,
    summary="Resend verification email",
)
async def resend_verification(email: str) -> MessageResponse:
    """Send a new verification email to the user's registered address."""
    return MessageResponse(
        message="If the email is registered, a verification link has been sent"
    )


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    summary="Request password reset",
)
async def forgot_password(request: ForgotPasswordRequest) -> MessageResponse:
    """Send a password reset link to the user's email."""
    return MessageResponse(
        message="If the email is registered, a reset link has been sent"
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Reset password with token",
)
async def reset_password(request: ResetPasswordRequest) -> MessageResponse:
    """Reset the user's password using the token from the reset email."""
    return MessageResponse(message="Password has been reset successfully")
