#!/usr/bin/env python3
"""Simulate phrase freshness distribution over local exposure history."""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHRASES = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"


def load_phrases() -> list[dict]:
    return json.loads(PHRASES.read_text(encoding="utf-8"))


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


def score(phrase: dict, stats: dict, now: datetime) -> float:
    freshness = phrase.get("freshness", {})
    pid = phrase["id"]
    cluster = freshness.get("semanticCluster", "general")
    cadence = freshness.get("cadenceGroup", "general")
    lifecycle = freshness.get("lifecycle", "active")
    return (
        item_freshness(pid, stats, now)
        * cluster_freshness(cluster, stats)
        * cadence_freshness(cadence, stats)
        * lifecycle_boost(lifecycle)
    )


def pick(phrases: list[dict], history: list[dict], now: datetime, seed: int) -> dict:
    stats = history_stats(history, now)
    weighted = [(phrase, score(phrase, stats, now)) for phrase in phrases]
    weighted = [(phrase, weight) for phrase, weight in weighted if weight > 0]
    if not weighted:
        return phrases[seed % len(phrases)]
    total = sum(weight for _, weight in weighted)
    roll = (seed % 1_000_000) / 1_000_000 * total
    for phrase, weight in weighted:
        roll -= weight
        if roll <= 0:
            return phrase
    return weighted[-1][0]


def simulate(days: int = 60, users: int = 100) -> dict[str, float]:
    phrases = load_phrases()
    exact_7d = 0
    cluster_3 = 0
    cadence_consecutive = 0
    cadence_three_in_5 = 0
    anchor_count = 0
    total = 0
    fallback_count = 0

    for user in range(users):
        history: list[dict] = []
        start = datetime(2026, 6, 1, tzinfo=timezone.utc)
        for day in range(days):
            draws = 1 + ((user + day) % 6)
            for draw in range(draws):
                now = start + timedelta(days=day, hours=draw * 3)
                phrase = pick(phrases, history, now, seed=(user + 1) * 1009 + day * 97 + draw * 17)
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
