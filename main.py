from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import PhoneCandidate, ValidatedPhone, Base
from datetime import datetime

Base.metadata.create_all(bind=engine)
app = FastAPI()

class MarkRequest(BaseModel):
    sha256_id: str
    mobile_number: str
    disposition: str
    first_name: str = None
    last_name: str = None
    source: str = None
    agent_id: str = None

@app.post("/mark-number")
def mark_number(data: MarkRequest):
    db: Session = SessionLocal()
    now = datetime.utcnow()

    # Determine outcome
    if data.disposition in ["wrong_number", "disconnected", "no_answer"]:
        new_status = "failed"
    elif data.disposition in ["connected_good", "positive_interaction"]:
        new_status = "verified"
    else:
        raise HTTPException(status_code=400, detail="Invalid disposition")

    # Update phone_candidates
    candidate = db.query(PhoneCandidate).filter_by(
        sha256_id=data.sha256_id,
        mobile_number=data.mobile_number
    ).first()

    if candidate:
        candidate.status = new_status
        candidate.last_attempted_at = now
        candidate.last_attempted_by = data.agent_id
    else:
        # Insert if not already present (optional for flexibility)
        candidate = PhoneCandidate(
            sha256_id=data.sha256_id,
            mobile_number=data.mobile_number,
            first_name=data.first_name,
            last_name=data.last_name,
            source=data.source,
            priority_order=0,
            status=new_status,
            last_attempted_at=now,
            last_attempted_by=data.agent_id
        )
        db.add(candidate)

    # If verified, upsert into validated_phones
    if data.disposition in ["connected_good", "positive_interaction"]:
        existing = db.query(ValidatedPhone).filter_by(sha256_id=data.sha256_id).first()
        if existing:
            existing.mobile_number = data.mobile_number
            existing.verified_at = now
            if data.disposition == "positive_interaction":
                existing.positive_interaction = True
        else:
            new_verified = ValidatedPhone(
                sha256_id=data.sha256_id,
                mobile_number=data.mobile_number,
                first_name=data.first_name,
                last_name=data.last_name,
                wrong_number=False,
                disconnected=False,
                positive_interaction=(data.disposition == "positive_interaction"),
                verified_at=now
            )
            db.add(new_verified)

    db.commit()
    return {"status": "success", "updated_status": new_status}
