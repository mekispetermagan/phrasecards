from config import settings
from database import Base, engine, SessionLocal
from models import Phrase

phrases = [
    ("How are you?", "Hogy vagy?"),
    ("Good morning!", "Jó reggelt!"),
    ("Good night!", "Jó éjt!"),
    ("Bon appetit!", "Jó étvágyat!"),
    ("Bless you!", "Egészségedre!"),
    ("Thanks!", "Köszönöm!"),
    ("I love you.", "Szeretlek."),
]


def main():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    for (s, t) in phrases:
        db.add(
            Phrase(
                source=s,
                target=t,
                new=False,
                rating=3,
            )
        )
    db.commit()
    db.close()


if __name__ == "__main__":
    main()
