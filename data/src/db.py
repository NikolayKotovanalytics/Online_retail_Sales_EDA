import os
from sqlalchemy import create_engine
from dotenv import load_dotenv


load_dotenv()


def get_db_engine():
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "3306")
    database = os.getenv("DB_NAME", "UK_online_retail_db")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")

    if not user or not password:
        raise ValueError(
            "Missing DB_USER or DB_PASSWORD. Set them in your .env file."
        )

    connection_url = (
        f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"
    )

    return create_engine(connection_url)