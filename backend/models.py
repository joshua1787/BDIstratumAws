from sqlalchemy import Column, Integer, String, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import datetime

Base = declarative_base()

class CustomerInteractionDB(Base):
    __tablename__ = "customer_interactions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    customer_id = Column(String, index=True, nullable=False)
    event_type = Column(String, index=True, nullable=False)
    payload = Column(JSON, nullable=True) # Store the JSON payload
    received_at_server = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    # A specific ingested_at timestamp can be set by the app if needed,
    # otherwise received_at_server defaults to DB's now() on insert.
    ingested_at = Column(DateTime(timezone=True), default=datetime.datetime.now(datetime.timezone.utc), nullable=False)

    def __repr__(self):
        return f"<CustomerInteractionDB(id={self.id}, customer_id='{self.customer_id}', event_type='{self.event_type}')>"
