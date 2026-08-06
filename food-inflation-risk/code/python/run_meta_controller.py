#!/usr/bin/env python3
"""Compact Phase 10 replication from the processed monthly results.

The full data-engineering pipeline is retained in the archived research package.
This script reproduces the principal model ranking, dynamic-regret summaries,
and period comparisons used in the LaTeX manuscript from compact public CSVs.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd

PRIMARY = "Stress-override inertial expert mixture"
EXPERTS = [
    "Static empirical q90",
    "Fixed-persistence gate",
    "Global conformal (12m)",
    "Pure hierarchical conformal",
]


def load_monthly(data_dir: Path) -> pd.DataFrame:
    files = sorted(data_dir.glob("phase10_monthly_metrics_*.csv"))
    if not files:
        raise FileNotFoundError(f"No monthly metric CSVs found in {data_dir}")
    df = pd.concat((pd.read_csv(path) for path in files), ignore_index=True)
    df["date"] = pd.to_datetime(df["date"])
    required = {
        "dataset", "date", "model", "n", "pinball_loss_q90",
        "coverage_y_le_q90", "dynamic_regret",
    }
    missing = required.difference(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")
    return df


def pooled_metrics(monthly: pd.DataFrame) -> pd.DataFrame:
    post = monthly.loc[monthly["date"] >= "2023-01-01"].copy()
    post["weighted_loss"] = post["n"] * post["pinball_loss_q90"]
    post["weighted_coverage"] = post["n"] * post["coverage_y_le_q90"]
    out = (
        post.groupby(["dataset", "model"], as_index=False)
        .agg(
            n=("n", "sum"),
            months=("date", "nunique"),
            weighted_loss=("weighted_loss", "sum"),
            weighted_coverage=("weighted_coverage", "sum"),
            equal_month_pinball=("pinball_loss_q90", "mean"),
            dynamic_regret=("dynamic_regret", "mean"),
        )
    )
    out["pinball_loss_q90"] = out["weighted_loss"] / out["n"]
    out["coverage_y_le_q90"] = out["weighted_coverage"] / out["n"]
    return out.drop(columns=["weighted_loss", "weighted_coverage"])


def oracle_gap(monthly: pd.DataFrame) -> pd.DataFrame:
    post = monthly.loc[monthly["date"] >= "2023-01-01"].copy()
    oracle = (
        post.loc[post["model"].isin(EXPERTS)]
        .groupby(["dataset", "date"], as_index=False)["pinball_loss_q90"]
        .min()
        .rename(columns={"pinball_loss_q90": "oracle_loss"})
    )
    merged = post.merge(oracle, on=["dataset", "date"], how="left")
    summary = (
        merged.groupby(["dataset", "model"], as_index=False)
        .agg(
            model_loss=("pinball_loss_q90", "mean"),
            oracle_loss=("oracle_loss", "mean"),
        )
    )
    static = (
        summary.loc[summary["model"] == "Static empirical q90", ["dataset", "model_loss"]]
        .rename(columns={"model_loss": "static_loss"})
    )
    summary = summary.merge(static, on="dataset", how="left")
    denom = summary["static_loss"] - summary["oracle_loss"]
    summary["oracle_gap_closed_vs_static"] = (
        (summary["static_loss"] - summary["model_loss"]) / denom.where(denom != 0)
    )
    return summary


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", type=Path, default=Path("data/processed"))
    parser.add_argument("--output-dir", type=Path, default=Path("results/recomputed"))
    args = parser.parse_args()

    monthly = load_monthly(args.data_dir)
    metrics = pooled_metrics(monthly)
    regret = oracle_gap(monthly)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    metrics.to_csv(args.output_dir / "recomputed_model_metrics.csv", index=False)
    regret.to_csv(args.output_dir / "recomputed_oracle_gap.csv", index=False)

    primary = metrics.loc[metrics["model"] == PRIMARY].copy()
    best_expert = (
        metrics.loc[metrics["model"].isin(EXPERTS)]
        .sort_values(["dataset", "pinball_loss_q90"])
        .groupby("dataset", as_index=False)
        .first()
    )
    comparison = primary.merge(
        best_expert[["dataset", "model", "pinball_loss_q90"]],
        on="dataset", suffixes=("_primary", "_best_expert"),
    )
    print(comparison[[
        "dataset", "pinball_loss_q90_primary", "coverage_y_le_q90",
        "model_best_expert", "pinball_loss_q90_best_expert",
    ]].to_string(index=False))


if __name__ == "__main__":
    main()
