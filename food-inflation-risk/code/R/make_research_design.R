#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "code/R/make_research_design.R"
project_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
figure_dir <- file.path(project_root, "manuscript", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

stages <- data.frame(
  x = 1:4,
  title = c("Base training", "Regime priors", "Model selection", "Exploratory evaluation"),
  period = c("Mar 2017-Dec 2020", "2021", "2022", "Jan 2023 onward"),
  detail = c(
    "NBS state-item panel",
    "Estimate regime-conditioned\nexpert priors",
    "Validation-only controller\nand hyperparameter selection",
    "NBS continuation and\nexternal WFP panel"
  ),
  group = c("Development", "Selection", "Selection", "Evaluation")
)

feedback <- data.frame(
  x = c(1.15, 2.50, 3.85),
  title = c("Forecast issued", "Outcome matures", "Loss becomes usable"),
  detail = c("Origin t", "At t + 3", "For origins t + 3 onward")
)

stage_arrows <- data.frame(
  x = c(1.47, 2.47, 3.47),
  xend = c(1.53, 2.53, 3.53),
  y = 1.05,
  yend = 1.05
)

feedback_arrows <- data.frame(
  x = c(1.65, 3.00),
  xend = c(2.00, 3.35),
  y = 0.28,
  yend = 0.28
)

p <- ggplot() +
  geom_segment(
    data = stage_arrows,
    aes(x = x, xend = xend, y = y, yend = yend),
    linewidth = 0.8,
    colour = "#4B5563",
    arrow = arrow(length = grid::unit(0.10, "inches"), type = "closed")
  ) +
  geom_rect(
    data = stages,
    aes(xmin = x - 0.46, xmax = x + 0.46, ymin = 0.73, ymax = 1.37, fill = group),
    colour = "white",
    linewidth = 0.9
  ) +
  geom_text(data = stages, aes(x = x, y = 1.20, label = title), fontface = "bold", size = 3.15) +
  geom_text(data = stages, aes(x = x, y = 1.04, label = period), fontface = "bold", size = 2.75) +
  geom_text(data = stages, aes(x = x, y = 0.86, label = detail), size = 2.45, lineheight = 0.95) +
  annotate(
    "text", x = 0.54, y = 0.56,
    label = "Delayed feedback for a three-month target",
    hjust = 0, fontface = "bold", size = 3.2, colour = "#1F2937"
  ) +
  geom_segment(
    data = feedback_arrows,
    aes(x = x, xend = xend, y = y, yend = yend),
    linewidth = 0.75,
    colour = "#4B5563",
    arrow = arrow(length = grid::unit(0.10, "inches"), type = "closed")
  ) +
  geom_rect(
    data = feedback,
    aes(xmin = x - 0.50, xmax = x + 0.50, ymin = 0.08, ymax = 0.47),
    fill = "#F3F4F6",
    colour = "#6B7280",
    linewidth = 0.65
  ) +
  geom_text(data = feedback, aes(x = x, y = 0.34, label = title), fontface = "bold", size = 2.95) +
  geom_text(data = feedback, aes(x = x, y = 0.19, label = detail), size = 2.55) +
  annotate(
    "text", x = 0.54, y = -0.05,
    label = "At origin t, adaptive updates use only errors attached to origins t-3 or earlier.",
    hjust = 0, fontface = "italic", size = 2.85, colour = "#4B5563"
  ) +
  scale_fill_manual(values = c("Development" = "#9ECAE1", "Selection" = "#A1D99B", "Evaluation" = "#FC9272")) +
  coord_cartesian(xlim = c(0.48, 4.52), ylim = c(-0.14, 1.48), clip = "off") +
  labs(title = "Research design and delayed information flow") +
  theme_void(base_size = 10.5, base_family = "sans") +
  theme(
    plot.title = element_text(face = "bold", size = 12.3, margin = margin(b = 10)),
    legend.position = "none",
    plot.margin = margin(10, 10, 8, 10)
  )

ggsave(file.path(figure_dir, "fig1_research_design.pdf"), p, width = 7.2, height = 4.25, units = "in", device = "pdf")
ggsave(file.path(figure_dir, "fig1_research_design.png"), p, width = 7.2, height = 4.25, units = "in", dpi = 320, bg = "white")

message("Regenerated publication-safe research-design figure in: ", figure_dir)
