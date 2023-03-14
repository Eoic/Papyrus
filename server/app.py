from typing import Union
from pydantic import BaseModel
from fastapi import FastAPI, Depends, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestFormStrict

# https://fastapi.tiangolo.com/tutorial/security/simple-oauth2/

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

fake_users_db = {
    "johndoe": {
        "username": "johndoe",
        "full_name": "John Doe",
        "email": "johndoe@example.com",
        "hashed_password": "fakehashedsecret",
    },
    "alice": {
        "username": "alice",
        "full_name": "Alice Wonderson",
        "email": "alice@example.com",
        "hashed_password": "fakehashedsecret2",
    },
}

class User(BaseModel):
    username: str
    email: Union[str, None] = None
    full_name: Union[str, None] = None


class UserInDB(User):
    hashed_password: Union[str, None] = None


def fake_hash_password(password: str):
    return "fakehashed" + password


def fake_decode_token(token):
    return User(
        username=token + "fakedecoded",
        email="john@example.com",
        full_name="John Doe"
    )


async def get_current_user(token: str = Depends(oauth2_scheme)):
    user = fake_decode_token(token)
    return user


@app.get("/")
async def root():
    return {"message": "Hello World!"}


@app.get("/users/me")
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.get("/books")
async def get_books(token: str = Depends(oauth2_scheme)):
    return {"books": [], "token": token}


@app.post("/upload")
async def upload_book(files: list[UploadFile]):
    return {"uploaded": [file.filename for file in files]}
