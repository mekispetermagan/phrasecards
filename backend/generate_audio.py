from database import SessionLocal
from tts import generate_missing_audio


def main() -> None:
    db = SessionLocal()
    try:
        generated, failed = generate_missing_audio(db)
        print(f"Generated: {generated}; failed: {failed}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
