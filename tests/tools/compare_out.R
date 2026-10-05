#!/usr/bin/env Rscript
#
# Compares two SelAction .out reports with a numeric tolerance.
#
# Usage:
#   Rscript tests/tools/compare_out.R expected.out actual.out [--abs X] [--rel Y]
#
# Each line is split into text and numbers.
#   - Text must match exactly, except that runs of blanks count as one
#     (a sign change from -0.000 to 0.000 shifts a blank).
#   - Numbers with a decimal point must agree within one unit in the last
#     printed digit (0.001 for 12.345), unless --abs and/or --rel are
#     given, in which case a pair passes if it is within either. -0.000
#     equals 0.000.
#   - Integers (no decimal point) must match exactly.
#   - Both files must have the same number of lines.
#
# Exit codes: 0 match, 1 mismatch, 2 usage or file error.
#
# Base R only, so it runs wherever R is installed.

args <- commandArgs(trailingOnly = TRUE)

usage <- function(msg) {
  if (!missing(msg)) message("error: ", msg)
  message("usage: compare_out.R expected.out actual.out [--abs X] [--rel Y]")
  quit(status = 2)
}

files <- character(0)
abs_tol <- NA_real_
rel_tol <- NA_real_
i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (a %in% c("--abs", "--rel")) {
    if (i == length(args)) usage(paste(a, "needs a value"))
    v <- suppressWarnings(as.numeric(args[i + 1]))
    if (is.na(v) || v < 0) usage(paste(a, "needs a non-negative number"))
    if (a == "--abs") abs_tol <- v else rel_tol <- v
    i <- i + 2
  } else if (startsWith(a, "--")) {
    usage(paste("unknown option", a))
  } else {
    files <- c(files, a)
    i <- i + 1
  }
}
if (length(files) != 2) usage("need exactly two files")
for (f in files) if (!file.exists(f)) usage(paste("file not found:", f))

expected <- readLines(files[1], warn = FALSE)
actual <- readLines(files[2], warn = FALSE)

# A number: optional sign, digits with an optional decimal point, optional
# exponent (Fortran may print D as well as E).
num_re <- "[-+]?([0-9]+\\.[0-9]*|\\.[0-9]+|[0-9]+)([EeDd][-+]?[0-9]+)?"

split_line <- function(line) {
  m <- gregexpr(num_re, line, perl = TRUE)[[1]]
  nums <- if (m[1] == -1) character(0) else regmatches(line, list(m))[[1]]
  text <- if (m[1] == -1) line else {
    s <- line
    regmatches(s, list(m)) <- list(rep("#", length(nums)))
    s
  }
  text <- gsub("[[:space:]]+", " ", trimws(text))
  list(text = text, nums = nums)
}

# One unit in the last printed digit, or NA for an integer.
last_digit_unit <- function(tok) {
  mant <- sub("[EeDd].*$", "", tok)
  if (!grepl(".", mant, fixed = TRUE)) return(NA_real_)
  decimals <- nchar(sub("^.*\\.", "", mant))
  expo <- if (grepl("[EeDd]", tok)) as.numeric(sub("^.*[EeDd]", "", tok)) else 0
  10^(expo - decimals)
}

to_num <- function(tok) as.numeric(chartr("Dd", "Ee", tok))

numbers_agree <- function(e, a) {
  ve <- to_num(e)
  va <- to_num(a)
  ue <- last_digit_unit(e)
  ua <- last_digit_unit(a)
  if (is.na(ue) && is.na(ua)) return(ve == va)
  diff <- abs(ve - va)
  if (!is.na(abs_tol) || !is.na(rel_tol)) {
    ok_abs <- !is.na(abs_tol) && diff <= abs_tol
    ok_rel <- !is.na(rel_tol) && diff <= rel_tol * max(abs(ve), abs(va))
    return(ok_abs || ok_rel)
  }
  unit <- max(ue, ua, na.rm = TRUE)
  diff <= unit * (1 + 1e-9)
}

problems <- character(0)
note <- function(msg) problems <<- c(problems, msg)

if (length(expected) != length(actual)) {
  note(sprintf("line count differs: expected %d, actual %d",
               length(expected), length(actual)))
}

for (k in seq_len(min(length(expected), length(actual)))) {
  se <- split_line(expected[k])
  sa <- split_line(actual[k])
  if (se$text != sa$text || length(se$nums) != length(sa$nums)) {
    note(sprintf("line %d text differs:\n  expected: %s\n  actual:   %s",
                 k, expected[k], actual[k]))
    next
  }
  for (j in seq_along(se$nums)) {
    if (!numbers_agree(se$nums[j], sa$nums[j])) {
      note(sprintf("line %d number %d differs: expected %s, actual %s\n  expected: %s\n  actual:   %s",
                   k, j, se$nums[j], sa$nums[j], expected[k], actual[k]))
      break
    }
  }
}

if (length(problems) == 0) quit(status = 0)

cat(sprintf("%d difference(s) between %s and %s\n",
            length(problems), files[1], files[2]))
cat(head(problems, 20), sep = "\n")
if (length(problems) > 20) cat(sprintf("... and %d more\n", length(problems) - 20))
quit(status = 1)
