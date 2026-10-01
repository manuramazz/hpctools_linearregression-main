#!/bin/bash
#SBATCH -J linreg_bench
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --exclusive
#SBATCH --mem=8G
#SBATCH -t 12:00:00
#SBATCH -o logs/slurm_%j.out
# =============================================================================
# run_bench.sh — 3 compilers x 4 opt levels x 3 configs x NRUNS runs
#
# Usage:
#   sbatch run_bench.sh <solver_label> [compilers...]
#     sbatch run_bench.sh ge                 # gcc icc icx
#     sbatch run_bench.sh gj gcc             # only gcc (split into several jobs)
#
# <solver_label> only tags the results (ge / gj): the solver actually used is
# the one wired in linreg.c when the job compiles.
#
# Output (logs/):
#   raw_<solver>.csv      one row per run
#   summary_<solver>.csv  mean and std of every phase per variant/config
#   <solver>_<cc>_<opt>.log  full program output, for traceability
# =============================================================================

set -u -o pipefail

SOLVER=${1:?usage: run_bench.sh <solver_label> [compilers...]}
shift
if [ $# -gt 0 ]; then COMPILERS=("$@"); else COMPILERS=(gcc icc icx); fi

OPTS=(O0 O2 O3 Ofast)
CONFIGS=("20000 50" "50000 300" "2000 2000")
NRUNS=10

# Module names in FT3 (check with: module spider gcc / module spider intel)
GCC_MODULE="gcc/10.1.0"
INTEL_MODULE="intel/2021.3.0"

cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")}"
mkdir -p logs bin

RAW="logs/raw_${SOLVER}.csv"
SUMMARY="logs/summary_${SOLVER}.csv"
[ -f "$RAW" ] || echo "solver,compiler,opt,N,p,run,t_xtx,t_xty,t_solve,t_total,max_diff,rms" > "$RAW"

load_compiler() {
  module purge
  case "$1" in
    gcc)     module load "$GCC_MODULE" ;;
    icc|icx) module load "$INTEL_MODULE" ;;
    *) echo "Unknown compiler: $1" >&2; return 1 ;;
  esac
}

# Extract "t_xtx t_xty t_solve max_diff rms" from the program output
parse_output() {
  awk -F': *' '
    /^Time taken by compute XtX/ { split($2, a, " "); xtx = a[1] }
    /^Time taken by compute Xty/ { split($2, a, " "); xty = a[1] }
    /^Time taken by solver/      { split($2, a, " "); sol = a[1] }
    /^Max \|beta/                { maxd = $2 }
    /^RMS \|beta/                { rms  = $2 }
    END { print xtx, xty, sol, maxd, rms }'
}

echo "== Job ${SLURM_JOB_ID:-local} on $(hostname) — solver=$SOLVER compilers=${COMPILERS[*]}"
lscpu | grep -E "Model name|L1d|L2|L3" || true

for cc in "${COMPILERS[@]}"; do
  load_compiler "$cc" || continue
  echo "== $cc: $($cc --version | head -1)"

  # -B: always rebuild, so the binary uses the solver currently in linreg.c
  if ! make -B all CC="$cc"; then
    echo "Build failed for $cc, skipping" >&2
    continue
  fi

  for opt in "${OPTS[@]}"; do
    bin="bin/linreg_${cc}_${opt}"
    log="logs/${SOLVER}_${cc}_${opt}.log"
    : > "$log"

    for cfg in "${CONFIGS[@]}"; do
      read -r N p <<< "$cfg"
      for run in $(seq 1 "$NRUNS"); do
        if ! out=$("$bin" "$N" "$p"); then
          echo "Run failed: $bin $N $p (run $run)" >&2
          continue
        fi
        printf '%s\n\n' "$out" >> "$log"

        read -r t_xtx t_xty t_solve max_diff rms <<< "$(parse_output <<< "$out")"
        t_total=$(awk -v a="$t_xtx" -v b="$t_xty" -v c="$t_solve" 'BEGIN { printf "%.6f", a + b + c }')

        echo "$SOLVER,$cc,$opt,$N,$p,$run,$t_xtx,$t_xty,$t_solve,$t_total,$max_diff,$rms" >> "$RAW"
        echo "$cc $opt N=$N p=$p run=$run total=${t_total}s max_diff=$max_diff"
      done
    done
  done
done

# Mean and (sample) std per solver/compiler/opt/N/p over all rows in RAW
awk -F, '
  NR == 1 { next }
  {
    k = $1 "," $2 "," $3 "," $4 "," $5
    if (!(k in n)) order[++nk] = k
    n[k]++
    for (c = 7; c <= 12; c++) { s[k, c] += $c; q[k, c] += $c * $c }
  }
  END {
    print "solver,compiler,opt,N,p,runs,xtx_mean,xtx_std,xty_mean,xty_std,solve_mean,solve_std,total_mean,total_std,max_diff_mean,rms_mean"
    for (i = 1; i <= nk; i++) {
      k = order[i]; line = k "," n[k]
      for (c = 7; c <= 10; c++) {
        m = s[k, c] / n[k]
        v = (n[k] > 1) ? (q[k, c] - n[k] * m * m) / (n[k] - 1) : 0
        line = line sprintf(",%.6f,%.6f", m, (v > 0) ? sqrt(v) : 0)
      }
      line = line sprintf(",%.6e,%.6e", s[k, 11] / n[k], s[k, 12] / n[k])
      print line
    }
  }' "$RAW" > "$SUMMARY"

echo "== Done. Raw: $RAW  Summary: $SUMMARY"
