from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .config import settings # Import our settings
from .models import Base # Import Base from our models.py
import boto3
import json
import sys

# --- ADD THESE DEBUG LINES ---
print("--- DEBUGGING SETTINGS (from database.py) ---")
print(f"settings.DATABASE_URL (initial): {settings.DATABASE_URL}")
print(f"settings.DB_CREDENTIALS_SECRET_ARN: {settings.DB_CREDENTIALS_SECRET_ARN}")
print(f"settings.AWS_REGION: {settings.AWS_REGION}")
print(f"settings.DB_HOST: {settings.DB_HOST}")
print(f"settings.DB_PORT: {settings.DB_PORT}")
print(f"settings.DB_NAME: {settings.DB_NAME}")
print(f"settings.DB_USER: {settings.DB_USER}")
# print(f"settings.DB_PASSWORD: {settings.DB_PASSWORD}") # Password printing is optional for debugging, uncomment if needed but be careful
print("--- END DEBUGGING SETTINGS ---")
# --- END OF DEBUG LINES ---

def get_db_credentials_from_secrets_manager(secret_arn: str, region_name: str) -> dict:
    """Fetches DB credentials from AWS Secrets Manager."""
    print(f"Attempting to fetch secret: {secret_arn} from region: {region_name}")
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
        print("Successfully fetched secret metadata.")
    except Exception as e:
        print(f"Error fetching secret from Secrets Manager: {e}")
        raise e
    else:
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            print("Successfully retrieved SecretString.")
            return json.loads(secret)
        else:
            print("Secret is binary, not string. Cannot process.")
            raise ValueError("Secret is binary, not string.")


if not settings.DATABASE_URL:
    print("DATABASE_URL not pre-set. Attempting to construct it...")
    if settings.DB_CREDENTIALS_SECRET_ARN and settings.AWS_REGION:
        print(f"Attempting to use Secrets Manager. ARN: {settings.DB_CREDENTIALS_SECRET_ARN}, Region: {settings.AWS_REGION}")
        try:
            creds = get_db_credentials_from_secrets_manager(
                settings.DB_CREDENTIALS_SECRET_ARN, # Corrected: was DB_CREDENTIALS_SECRET_arn (lowercase arn)
                settings.AWS_REGION
            )
            
            # Use .get for all credential parts to avoid KeyError if not in secret
            # Fallback to settings (from .env) if not found in secret
            db_user_from_secret = creds.get('username')
            db_password_from_secret = creds.get('password')

            # Host, port, dbname primarily from .env as they are less secret and more config
            # but can be overridden by secret if keys exist there
            db_host = creds.get('host', settings.DB_HOST) 
            db_port = creds.get('port', settings.DB_PORT) 
            db_name = creds.get('dbname', settings.DB_NAME) 

            # User and password MUST come from secret if this path is taken.
            # If they are not in the secret, something is wrong with the secret content.
            if not db_user_from_secret or not db_password_from_secret:
                print("CRITICAL: 'username' or 'password' not found in the fetched secret.")
                # Attempt to use .env user/password as a last resort ONLY if host/port/name are also from .env
                if not all([settings.DB_USER, settings.DB_PASSWORD, settings.DB_HOST, settings.DB_PORT, settings.DB_NAME]):
                     sys.exit("Database configuration error: Secret missing credentials, and .env fallback incomplete.")
                else: # This case means secret fetch failed for user/pass, but other DB details are in .env
                    print("Warning: Using DB_USER and DB_PASSWORD from .env as they were not in the fetched secret or secret fetch failed for them.")
                    db_user = settings.DB_USER
                    db_password = settings.DB_PASSWORD
            else:
                db_user = db_user_from_secret
                db_password = db_password_from_secret

            # Ensure host, port, db_name are available (either from secret or .env)
            if not all([db_host, db_port, db_name]):
                print(f"CRITICAL: Missing DB host, port, or name. Host: {db_host}, Port: {db_port}, Name: {db_name}")
                # Check if .env has them if they weren't in secret or settings object
                if not all([settings.DB_HOST, settings.DB_PORT, settings.DB_NAME]):
                    sys.exit("Database configuration error: DB host/port/name missing from both secret and .env.")
                else: # This should already be covered by creds.get defaulting to settings.DB_HOST etc.
                    db_host = settings.DB_HOST
                    db_port = settings.DB_PORT
                    db_name = settings.DB_NAME
            
            settings.DATABASE_URL = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
            print(f"Successfully constructed DATABASE_URL using Secrets Manager (and .env for host/port/name if needed): {settings.DATABASE_URL.split('@')[0]}@...") # Avoid printing full creds

        except Exception as e:
            print(f"Could not construct DATABASE_URL using Secrets Manager: {e}")
            # Fallback to constructing from individual .env DB_* variables if Secrets Manager fails
            if all([settings.DB_USER, settings.DB_PASSWORD, settings.DB_HOST, settings.DB_PORT, settings.DB_NAME]):
                settings.DATABASE_URL = f"postgresql://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
                print(f"Using DATABASE_URL constructed from .env variables due to Secrets Manager failure: {settings.DATABASE_URL.split('@')[0]}@...")
            else:
                print("CRITICAL: Failed to get DB credentials from Secrets Manager and .env is also incomplete for fallback.")
                sys.exit("Database configuration error.")
    
    elif all([settings.DB_USER, settings.DB_PASSWORD, settings.DB_HOST, settings.DB_PORT, settings.DB_NAME]):
        # Construct DATABASE_URL from .env if Secret ARN not provided but other DB vars are
        settings.DATABASE_URL = f"postgresql://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
        print(f"Constructed DATABASE_URL from .env variables (Secrets Manager ARN was not provided): {settings.DATABASE_URL.split('@')[0]}@...")
    else:
        print("CRITICAL: Database connection details not configured in .env (neither full URL, nor Secret ARN, nor all individual DB_* components).")
        sys.exit("Database configuration error.")

if not settings.DATABASE_URL:
    # This check is redundant if the above sys.exit() calls are effective, but as a final safeguard:
    print("CRITICAL: DATABASE_URL is still not set after all attempts. Exiting.")
    sys.exit("Fatal: DATABASE_URL could not be determined.")

print(f"Final DATABASE_URL to be used by SQLAlchemy: {settings.DATABASE_URL.split('@')[0]}@...")

# SQLAlchemy setup
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_db_tables():
    """Creates database tables if they don't exist."""
    try:
        print("Attempting to create database tables via SQLAlchemy...")
        Base.metadata.create_all(bind=engine)
        print("Database tables checked/created successfully via SQLAlchemy.")
    except Exception as e:
        print(f"Error creating database tables via SQLAlchemy: {e}")
        print("Please ensure the database is reachable and credentials/URL are correct.")

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
