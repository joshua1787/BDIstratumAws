# main.py

from typing import List
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session

# Corrected absolute imports
import models
import database
import config # Assuming config.py is also in the same directory and needed

# Initialize the database engine if not already done in database.py
# (This part would depend on how your database.py is structured)
# Example: If create_db_tables() is in database.py and needs to be called
# from database import engine, create_db_tables # Adjust as per your database.py
# models.Base.metadata.create_all(bind=database.engine) # Or similar

# If you have a function to create tables, call it here or within get_db
# For example, if database.py has create_db_tables()
# database.create_db_tables() # Uncomment if you have this function and want tables created on app start

app = FastAPI(
    title="Stratum Backend API",
    description="API for managing customer interactions for Project Stratum",
    version="1.0.0",
)

# Dependency to get a SQLAlchemy DB session
def get_db():
    db = database.SessionLocal() # Assuming SessionLocal is defined in database.py
    try:
        yield db
    finally:
        db.close()

# Ensure database tables are created when the app starts
# This is a common pattern, but be careful in production environments (e.g., use Alembic migrations)
@app.on_event("startup")
async def startup_event():
    # This will ensure tables are created based on SQLAlchemy models
    # This line assumes models.Base is defined in models.py and database.engine is defined in database.py
    models.Base.metadata.create_all(bind=database.engine)
    print("Database tables ensured.")


# --- API Endpoints ---

# Root endpoint
@app.get("/")
async def read_root():
    return {"message": "Welcome to Stratum Backend API!"}

# Get all customer interactions
@app.get("/interactions/", response_model=List[models.CustomerInteractionDB]) # Assuming CustomerInteractionDB is your Pydantic model for response
def get_customer_interactions(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    interactions = db.query(models.CustomerInteraction).offset(skip).limit(limit).all()
    return interactions

# Create a new customer interaction
@app.post("/interactions/", response_model=models.CustomerInteractionDB, status_code=status.HTTP_201_CREATED)
def create_customer_interaction(interaction: models.CustomerInteractionCreate, db: Session = Depends(get_db)):
    db_interaction = models.CustomerInteraction(**interaction.dict())
    db.add(db_interaction)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction

# Get a single customer interaction by ID
@app.get("/interactions/{interaction_id}", response_model=models.CustomerInteractionDB)
def get_customer_interaction(interaction_id: int, db: Session = Depends(get_db)):
    interaction = db.query(models.CustomerInteraction).filter(models.CustomerInteraction.id == interaction_id).first()
    if interaction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Interaction not found")
    return interaction

# Update a customer interaction
@app.put("/interactions/{interaction_id}", response_model=models.CustomerInteractionDB)
def update_customer_interaction(interaction_id: int, interaction: models.CustomerInteractionCreate, db: Session = Depends(get_db)):
    db_interaction = db.query(models.CustomerInteraction).filter(models.CustomerInteraction.id == interaction_id).first()
    if db_interaction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Interaction not found")
    for key, value in interaction.dict().items():
        setattr(db_interaction, key, value)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction

# Delete a customer interaction
@app.delete("/interactions/{interaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_customer_interaction(interaction_id: int, db: Session = Depends(get_db)):
    db_interaction = db.query(models.CustomerInteraction).filter(models.CustomerInteraction.id == interaction_id).first()
    if db_interaction is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Interaction not found")
    db.delete(db_interaction)
    db.commit()
    return