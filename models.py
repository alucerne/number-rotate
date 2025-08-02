from sqlalchemy import Column, String, Boolean, Integer, DateTime
from database import Base
from datetime import datetime

class PhoneCandidate(Base):
    __tablename__ = "phone_candidates"
    id = Column(Integer, primary_key=True, index=True)
    sha256_id = Column(String, index=True)
    mobile_number = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    source = Column(String)
    priority_order = Column(Integer, default=0)
    status = Column(String, default="untested")  # 'untested', 'failed', 'verified'
    last_attempted_at = Column(DateTime)
    last_attempted_by = Column(String)

class ValidatedPhone(Base):
    __tablename__ = "validated_phones"
    sha256_id = Column(String, primary_key=True, index=True)
    mobile_number = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    wrong_number = Column(Boolean, default=False)
    disconnected = Column(Boolean, default=False)
    positive_interaction = Column(Boolean, default=False)
    verified_at = Column(DateTime, default=datetime.utcnow)
