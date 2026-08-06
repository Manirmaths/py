#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(scales)
  library(lubridate)
})

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "code/R/make_figures.R"
project_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
data_dir <- file.path(project_root, "data", "processed")
figure_dir <- file.path(project_root, "manuscript", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

model_metrics <- read_csv(file.path(data_dir, "phase10_model_metrics.csv"), show_col_types = FALSE)
monthly_metrics <- read_csv(file.path(data_dir, "phase10_monthly_metrics.csv"), show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
simulation_summary <- read_csv(file.path(data_dir, "phase10_simulation_summary.csv"), show_col_types = FALSE)

model_labels <- c(
  "Static empirical q90" = "Static empirical q90",
  "Fixed-persistence gate" = "Fixed-persistence gate",
  "Global conformal (12m)" = "Global conformal (12m)",
  "Pure hierarchical conformal" = "Pure hierarchical conformal",
  "Loss-aware inertial expert mixture" = "Loss-aware inertial mixture",
  "Stress-override inertial expert mixture" = "Stress-override meta-controller",
  "Meta-controller" = "Meta-controller",
  "Global conformal" = "Global conformal",
  "Static" = "Static"
)

model_order <- c(
  "Static empirical q90",
  "Fixed-persistence gate",
  "Global conformal (12m)",
  "Pure hierarchical conformal",
  "Loss-aware inertial expert mixture",
  "Stress-override inertial expert mixture"
)

palette_models <- c(
  "Static empirical q90" = "#7A7A7A",
  "Fixed-persistence gate" = "#3B6FB6",
  "Global conformal (12m)" = "#2A9D8F",
  "Pure hierarchical conformal" = "#E9C46A",
  "Loss-aware inertial expert mixture" = "#8C6BB1",
  "Stress-override inertial expert mixture" = "#C44E52",
  "Static" = "#7A7A7A",
  "Global conformal" = "#2A9D8F",
  "Meta-controller" = "#C44E52"
)

theme_manuscript <- function(base_size = 10.5) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.12), margin = margin(b = 7)),
      plot.subtitle = element_text(color = "#4D4D4D", margin = margin(b = 9)),
      plot.caption = element_text(color = "#5E5E5E", hjust = 0, size = rel(0.82)),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      axis.title = element_text(face = "bold"),
      legend.title = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
}

save_plot <- function(plot, stem, width, height) {
  ggsave(file.path(figure_dir, paste0(stem, ".pdf")), plot, width = width, height = height, units = "in", device = cairo_pdf)
  ggsave(file.path(figure_dir, paste0(stem, ".png")), plot, width = width, height = height, units = "in", dpi = 320, bg = "white")
}

# Figure 1: research design and delayed-feedback chronology -----------------
stages <- tibble::tribble(
  ~stage, ~start, ~end, ~y, ~fill_group, ~detail,
  "Base training", 2017.20, 2020.98, 1.00, "development", "NBS state-item panel\nMar 2017-Dec 2020",
  "Regime priors", 2021.00, 2021.98, 1.00, "selection", "Estimate regime-conditioned\nexpert priors",
  "Hyperparameter selection", 2022.00, 2022.98, 1.00, "selection", "Validation-only model\nand controller selection",
  "Exploratory evaluation", 2023.00, 2026.33, 1.00, "evaluation", "NBS continuation and\nexternal WFP panel"
) %>%
  mutate(mid = (start + end) / 2)

feedback <- tibble::tribble(
  ~x, ~xend, ~y, ~yend, ~label,
  2023.15, 2023.42, 0.34, 0.34, "Forecast issued at t",
  2023.42, 2023.92, 0.34, 0.34, "Outcome matures at t+3",
  2023.92, 2024.18, 0.34, 0.34, "Loss becomes usable"
)

p1 <- ggplot(stages) +
  geom_rect(aes(xmin = start, xmax = end, ymin = 0.70, ymax = 1.30, fill = fill_group), color = "white", linewidth = 0.8) +
  geom_text(aes(x = mid, y = 1.08, label = stage), fontface = "bold", size = 3.45) +
  geom_text(aes(x = mid, y = 0.89, label = detail), size = 2.75, lineheight = 0.95) +
  geom_segment(data = feedback, aes(x = x, xend = xend, y = y, yend = yend), inherit.aes = FALSE,
               arrow = arrow(length = unit(0.12, "inches"), type = "closed"), linewidth = 0.7, color = "#374151") +
  geom_text(data = feedback, aes(x = (x + xend) / 2, y = y - 0.11, label = label), inherit.aes = FALSE, size = 2.75) +
  annotate("text", x = 2017.25, y = 0.48, label = "Three-month target horizon: adaptive updates at origin t use only errors from origins t-3 or earlier.",
           hjust = 0, size = 3.0, fontface = "italic", color = "#4D4D4D") +
  scale_fill_manual(values = c("development" = "#9ECAE1", "selection" = "#A1D99B", "evaluation" = "#FC9272")) +
  scale_x_continuous(breaks = 2017:2026, limits = c(2017.1, 2026.45), expand = expansion(mult = c(0, 0))) +
  coord_cartesian(ylim = c(0.08, 1.42), clip = "off") +
  labs(title = "Research design and delayed information flow", x = NULL, y = NULL) +
  theme_manuscript(10.5) +
  theme(
    axis.text.y = element_blank(), axis.ticks.y = element_blank(), panel.grid = element_blank(),
    legend.position = "none", plot.margin = margin(10, 14, 12, 14)
  )
save_plot(p1, "fig1_research_design", 7.2, 4.25)

# Figures 2 and 3: model comparisons ---------------------------------------
plot_model_comparison <- function(dataset_name, title, stem) {
  df <- model_metrics %>%
    filter(dataset == dataset_name, split == "test_2023_onward", model %in% model_order) %>%
    mutate(
      model = factor(model, levels = rev(model_order)),
      label = model_labels[as.character(model)]
    )

  p <- ggplot(df, aes(x = pinball_loss_q90, y = model, fill = as.character(model))) +
    geom_col(width = 0.72) +
    geom_text(aes(label = sprintf("%.3f", pinball_loss_q90)), hjust = -0.12, size = 3.2) +
    scale_fill_manual(values = palette_models, guide = "none") +
    scale_y_discrete(labels = function(x) unname(model_labels[x])) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
    labs(title = title, subtitle = "Pooled q90 pinball loss; lower values indicate better tail forecasts.", x = "Pinball loss", y = NULL) +
    theme_manuscript(10.5)

  save_plot(p, stem, 7.2, 4.25)
}

plot_model_comparison(
  "NBS national continuation",
  "Post-2022 model comparison: NBS national continuation",
  "fig2_nbs_model_comparison"
)
plot_model_comparison(
  "WFP market observations",
  "Post-2022 model comparison: external WFP market panel",
  "fig3_wfp_model_comparison"
)

# Figures 4 and 5: cumulative regret --------------------------------------
regret_models <- c(
  "Static empirical q90",
  "Fixed-persistence gate",
  "Global conformal (12m)",
  "Pure hierarchical conformal",
  "Stress-override inertial expert mixture"
)

plot_cumulative_regret <- function(dataset_name, title, stem) {
  df <- monthly_metrics %>%
    filter(dataset == dataset_name, date >= as.Date("2023-01-01"), model %in% regret_models) %>%
    arrange(model, date) %>%
    group_by(model) %>%
    mutate(cumulative_regret = cumsum(pmax(dynamic_regret, 0))) %>%
    ungroup() %>%
    mutate(model_label = factor(model_labels[model], levels = model_labels[regret_models]))

  p <- ggplot(df, aes(x = date, y = cumulative_regret, color = model)) +
    geom_line(linewidth = 0.9) +
    scale_color_manual(values = palette_models, labels = model_labels[regret_models]) +
    scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y", expand = expansion(mult = c(0.01, 0.02))) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(title = title, subtitle = "Cumulative equal-month regret relative to the monthly hindsight oracle.", x = NULL, y = "Cumulative regret") +
    theme_manuscript(10.2) +
    theme(legend.position = "bottom", legend.text = element_text(size = 8.3)) +
    guides(color = guide_legend(nrow = 2, byrow = TRUE))

  save_plot(p, stem, 7.2, 4.0)
}

plot_cumulative_regret(
  "NBS national continuation",
  "Cumulative regret: NBS national continuation",
  "fig4_nbs_cumulative_regret"
)
plot_cumulative_regret(
  "WFP market observations",
  "Cumulative regret: external WFP market panel",
  "fig5_wfp_cumulative_regret"
)

# Figure 6: simulated regret ----------------------------------------------
simulation_models <- c("Static", "Fixed-persistence gate", "Global conformal", "Pure hierarchical conformal", "Meta-controller")
scenario_labels <- c(
  "abrupt_permanent" = "Abrupt\npermanent",
  "gradual_break_recovery" = "Gradual break\nand recovery",
  "heterogeneous_subgroups" = "Heterogeneous\nsubgroups",
  "no_break" = "No break",
  "temporary_recovery" = "Temporary\nrecovery",
  "volatility_break_recovery" = "Volatility break\nand recovery"
)

sim_df <- simulation_summary %>%
  filter(model %in% simulation_models) %>%
  mutate(
    scenario = factor(scenario, levels = names(scenario_labels), labels = unname(scenario_labels)),
    model = factor(model, levels = simulation_models)
  )

p6 <- ggplot(sim_df, aes(x = scenario, y = mean_dynamic_regret, fill = model)) +
  geom_col(position = position_dodge(width = 0.82), width = 0.74) +
  scale_fill_manual(values = palette_models, labels = c(
    "Static" = "Static",
    "Fixed-persistence gate" = "Fixed-persistence gate",
    "Global conformal" = "Global conformal",
    "Pure hierarchical conformal" = "Pure hierarchical conformal",
    "Meta-controller" = "Meta-controller"
  )) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
  labs(
    title = "Delayed-feedback simulation: dynamic regret",
    subtitle = "Mean regret relative to the monthly oracle across 60 replicates per scenario.",
    x = NULL, y = "Mean dynamic regret"
  ) +
  theme_manuscript(10.2) +
  theme(axis.text.x = element_text(size = 8.8), legend.text = element_text(size = 8.4)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))
save_plot(p6, "fig6_simulation_regret", 7.2, 4.0)

message("Generated six ggplot2 manuscript figures in: ", figure_dir)
