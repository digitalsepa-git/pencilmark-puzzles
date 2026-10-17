#!/usr/bin/env python3
"""Rakip uygulamaların App Store yorumlarını tarar ve şikâyet temalarını sayar.

Kullanım:
    python3 docs/arastirma/arac/rakip-yorum-tarama.py

İki açık Apple uç noktası kullanıyor, anahtar gerekmiyor:
  - iTunes Search API    → uygulama kimliği, puan, oy sayısı, son güncelleme
  - Customer Reviews RSS → yorum metinleri (sayfa başına 50, en fazla ~10 sayfa)

Yorum metinleri repoya kaydedilmiyor: üçüncü parti içerik ve kişisel veri.
Çıktı yalnızca sayılar; yorumların kendisi geçici dizinde kalıyor.
"""

import json
import re
import sys
import urllib.request
from collections import Counter

SEARCH = "https://itunes.apple.com/search?term={}&country=us&entity=software&limit=12"
REVIEWS = "https://itunes.apple.com/us/rss/customerreviews/page={}/id={}/sortby=mostrecent/json"

TERMS = ["kakuro", "calcudoku", "mathdoku", "slitherlink", "hashi", "hitori"]

# Şikâyet temaları. Desenler yorum başlığı + gövdesinde aranıyor.
THEMES = {
    "reklam": r"\b(ads?|advert|commercial)\b",
    "performans/çökme": r"(slow|lag|freez|crash|hang|unrespons|glitch)",
    "ödeme modeli": r"(paywall|subscri|expensive|rip ?off|packs?\b|credits?|price|pay for)",
    "kalem işareti": r"(pencil|annotat|candidate)",
    "ipucu": r"\b(hint|solver)\b",
    "ilerleme kaybı": r"(lost (my )?(progress|data)|didn.?t save|not saved|wiped)",
    "bulmaca tükenmesi": r"(run out|ran out|same puzzle|need more puzzles|more levels)",
    "tahmin gerektirme": r"(requires? guess|guessing|trial and error|no solution|unsolvable)",
    "okunabilirlik": r"(contrast|hard to see|too small|tiny|font|dark mode)",
    "öğretici": r"(tutorial|how to play|rules|instruction)",
    "terk edilmişlik": r"(no (longer|more) updat|abandon|not updated)",
}


def fetch(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.loads(response.read().decode())


def main():
    apps = {}
    for term in TERMS:
        for result in fetch(SEARCH.format(term)).get("results", []):
            apps[str(result["trackId"])] = result

    reviews = []
    for app_id in apps:
        if (apps[app_id].get("userRatingCount") or 0) < 20:
            continue
        for page in (1, 2, 3):
            try:
                feed = fetch(REVIEWS.format(page, app_id)).get("feed", {})
            except Exception as error:  # ağ hatası taramayı durdurmasın
                print(f"uyarı: {app_id} sayfa {page}: {error}", file=sys.stderr)
                continue
            entries = feed.get("entry") or []
            if isinstance(entries, dict):
                entries = [entries]
            for entry in entries:
                if "im:rating" not in entry:
                    continue
                reviews.append({
                    "app": app_id,
                    "rating": int(entry["im:rating"]["label"]),
                    "text": entry["title"]["label"] + " " + entry["content"]["label"],
                })

    low = [r for r in reviews if r["rating"] <= 3]
    print(f"{len(reviews)} yorum, {len(low)} tanesi 1-3 yıldız\n")

    counts = Counter()
    for name, pattern in THEMES.items():
        expression = re.compile(pattern, re.I)
        counts[name] = sum(1 for r in low if expression.search(r["text"]))

    for name, count in counts.most_common():
        share = 100 * count / len(low) if low else 0
        print(f"{name:22} {count:4}  {share:5.0f}%")


if __name__ == "__main__":
    main()
