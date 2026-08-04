#!/usr/bin/env python3
"""Simulate phrase freshness distribution over local exposure history."""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHRASES = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"
NEGATIVE_MULTIPLIER = 0.12


def load_phrases() -> list[dict]:
    return json.loads(PHRASES.read_text(encoding="utf-8"))


def stable_hash64(value: str) -> int:
    result = 0xCBF29CE484222325
    for byte in value.encode("utf-8"):
        result ^= byte
        result = (result * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return result


def stable_unit(value: str) -> float:
    return (stable_hash64(value) % 1_000_000) / 1_000_000


def season_for_month(month: int) -> str:
    if month in (3, 4, 5):
        return "spring"
    if month in (6, 7, 8):
        return "summer"
    if month in (9, 10, 11):
        return "autumn"
    return "winter"


def daypart_for_hour(hour: int) -> str:
    if 5 <= hour < 11:
        return "morning"
    if 11 <= hour < 14:
        return "noon"
    if 14 <= hour < 18:
        return "afternoon"
    if 18 <= hour < 22:
        return "evening"
    return "late_night"


def simulated_context_tags(now: datetime, user: int) -> set[str]:
    season = season_for_month(now.month)
    weather = ("clear", "rain", "windy", "overcast")[(now.timetuple().tm_yday + user) % 4]
    temp = {
        "spring": "mild",
        "summer": "hot",
        "autumn": "mild",
        "winter": "cold",
    }[season]
    return {
        f"season:{season}",
        f"month:{now.month}",
        f"weekday:{((now.weekday() + 1) % 7) + 1}",
        f"daypart:{daypart_for_hour(now.hour)}",
        f"weather:{weather}",
        f"temp:{temp}",
    }


def context_weight(phrase: dict, active_tags: set[str]) -> float:
    dispatch = phrase.get("dispatch") or {"universal": True, "onlyWhen": [], "boost": []}
    required = dispatch.get("onlyWhen") or []
    if required and not any(tag in active_tags for tag in required):
        return 0

    weight = 1.0 if dispatch.get("universal", True) else 0.6
    for boost in dispatch.get("boost") or []:
        if boost.get("tag") in active_tags:
            weight += float(boost.get("weight", 0))
    for tag in dispatch.get("negative") or []:
        if tag in active_tags:
            weight *= NEGATIVE_MULTIPLIER
    return max(0, weight)


def history_stats(history: list[dict], now: datetime) -> dict:
    day_ago = now - timedelta(days=1)
    week_ago = now - timedelta(days=7)
    last_by_item: dict[str, datetime] = {}
    cluster_day: dict[str, int] = {}
    cluster_week: dict[str, int] = {}
    for exposure in history:
        last_by_item[exposure["id"]] = exposure["shownAt"]
        if exposure["shownAt"] >= day_ago:
            cluster_day[exposure["cluster"]] = cluster_day.get(exposure["cluster"], 0) + 1
        if exposure["shownAt"] >= week_ago:
            cluster_week[exposure["cluster"]] = cluster_week.get(exposure["cluster"], 0) + 1
    return {
        "last_by_item": last_by_item,
        "recent_clusters": {exposure["cluster"] for exposure in history[-3:]},
        "last_cadence": history[-1]["cadence"] if history else None,
        "recent_five_cadence_counts": {
            cadence: sum(1 for exposure in history[-5:] if exposure["cadence"] == cadence)
            for cadence in {exposure["cadence"] for exposure in history[-5:]}
        },
        "cluster_day": cluster_day,
        "cluster_week": cluster_week,
    }


def item_freshness(pid: str, stats: dict, now: datetime) -> float:
    last = stats["last_by_item"].get(pid)
    if last is None:
        return 1
    age = now - last
    if age < timedelta(days=7):
        return 0
    if age < timedelta(days=30):
        return 0.65
    return 1


def cluster_freshness(cluster: str, stats: dict) -> float:
    if cluster in stats["recent_clusters"]:
        return 0.35
    if stats["cluster_day"].get(cluster, 0) >= 2:
        return 0.5
    if stats["cluster_week"].get(cluster, 0) >= 5:
        return 0.75
    return 1


def cadence_freshness(cadence: str, stats: dict) -> float:
    if stats["last_cadence"] == cadence:
        return 0.45
    if stats["recent_five_cadence_counts"].get(cadence, 0) >= 3:
        return 0.7
    return 1


def lifecycle_boost(lifecycle: str) -> float:
    return {
        "new": 1.18,
        "anchor": 1.05,
        "cooling": 0.65,
        "retired": 0,
    }.get(lifecycle, 1)


def score(phrase: dict, stats: dict, now: datetime, active_tags: set[str]) -> float:
    freshness = phrase.get("freshness", {})
    pid = phrase["id"]
    cluster = freshness.get("semanticCluster", "general")
    cadence = freshness.get("cadenceGroup", "general")
    lifecycle = freshness.get("lifecycle", "active")
    return (
        context_weight(phrase, active_tags)
        * item_freshness(pid, stats, now)
        * cluster_freshness(cluster, stats)
        * cadence_freshness(cadence, stats)
        * lifecycle_boost(lifecycle)
    )


def pick(
    phrases: list[dict],
    history: list[dict],
    now: datetime,
    seed: str,
    active_tags: set[str],
) -> dict:
    stats = history_stats(history, now)
    weighted = [(phrase, score(phrase, stats, now, active_tags)) for phrase in phrases]
    weighted = [(phrase, weight) for phrase, weight in weighted if weight > 0]
    if not weighted:
        eligible = [
            phrase
            for phrase in phrases
            if context_weight(phrase, active_tags) > 0
            and phrase.get("freshness", {}).get("lifecycle") != "retired"
        ]
        return (eligible or phrases)[stable_hash64(seed) % len(eligible or phrases)]
    total = sum(weight for _, weight in weighted)
    roll = stable_unit(seed) * total
    for phrase, weight in weighted:
        roll -= weight
        if roll <= 0:
            return phrase
    return weighted[-1][0]


def simulate(days: int = 365, users: int = 30) -> dict[str, float]:
    phrases = load_phrases()
    exact_7d = 0
    cluster_3 = 0
    cadence_consecutive = 0
    cadence_three_in_5 = 0
    anchor_count = 0
    total = 0
    fallback_count = 0
    context_violation_count = 0
    retired_count = 0
    lifecycle_counts = {
        "active": 0,
        "anchor": 0,
        "cooling": 0,
        "new": 0,
    }

    for user in range(users):
        history: list[dict] = []
        start = datetime(2026, 1, 1, tzinfo=timezone.utc)
        for day in range(days):
            draws = 1 + ((user + day) % 6)
            for draw in range(draws):
                now = start + timedelta(days=day, hours=draw * 3)
                active_tags = simulated_context_tags(now, user)
                seed = f"user-{user}|{now.isoformat()}|draw-{draw}"
                phrase = pick(phrases, history, now, seed=seed, active_tags=active_tags)
                freshness = phrase.get("freshness", {})
                pid = phrase["id"]
                cluster = freshness.get("semanticCluster", "general")
                cadence = freshness.get("cadenceGroup", "general")
                if any(e["id"] == pid and now - e["shownAt"] < timedelta(days=7) for e in history):
                    exact_7d += 1
                if any(e["cluster"] == cluster for e in history[-3:]):
                    cluster_3 += 1
                if history and history[-1]["cadence"] == cadence:
                    cadence_consecutive += 1
                if sum(1 for e in history[-5:] if e["cadence"] == cadence) >= 3:
                    cadence_three_in_5 += 1
                if phrase.get("layer") == "anchor":
                    anchor_count += 1
                if pid == "fallback":
                    fallback_count += 1
                required = phrase.get("dispatch", {}).get("onlyWhen") or []
                if required and not any(tag in active_tags for tag in required):
                    context_violation_count += 1
                lifecycle = freshness.get("lifecycle", "active")
                if lifecycle == "retired":
                    retired_count += 1
                elif lifecycle in lifecycle_counts:
                    lifecycle_counts[lifecycle] += 1
                history.append({
                    "id": pid,
                    "cluster": cluster,
                    "cadence": cadence,
                    "shownAt": now,
                })
                history = history[-200:]
                total += 1

    return {
        "draws": total,
        "exact_repeat_within_7d": exact_7d / total,
        "cluster_repeat_within_3_draws": cluster_3 / total,
        "cadence_consecutive_repeat": cadence_consecutive / total,
        "cadence_three_in_5_draws": cadence_three_in_5 / total,
        "anchor_exposure_rate": anchor_count / total,
        "fallback_rate": fallback_count / total,
        "context_violation_rate": context_violation_count / total,
        "lifecycle_active_exposure_rate": lifecycle_counts["active"] / total,
        "lifecycle_anchor_exposure_rate": lifecycle_counts["anchor"] / total,
        "lifecycle_cooling_exposure_rate": lifecycle_counts["cooling"] / total,
        "lifecycle_new_exposure_rate": lifecycle_counts["new"] / total,
        "retired_exposure_rate": retired_count / total,
    }


def main() -> None:
    metrics = simulate()
    for key, value in metrics.items():
        if key == "draws":
            print(f"{key}: {int(value)}")
        else:
            print(f"{key}: {value:.4f}")


if __name__ == "__main__":
    main()
