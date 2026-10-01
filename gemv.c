#include "gemv.h"
/* -------------------------------------------------------------------------
 * TODO (STUDENT): compute_Xty
 *
 * Compute Xty = X^T * y, where:
 *   X   is N x p (row-major)
 *   y   is N     (vector)
 *   Xty is p     (output, caller-allocated)
 *
 *   Xty[a] = sum over i=0..N-1 of X[i][a] * y[i]
 * ---------------------------------------------------------------------- */
void compute_Xty(const double X[], const double y[], double Xty[],
                 int N, int p) {

  /* TODO: implement Xty = X^T * y here. */
  for (int a = 0; a < p; a++) {
    double s = 0.0;
    for (int i = 0; i < N; i++) {
      s += X[i*p + a] * y[i];
    }
    Xty[a] = s;
  }

}
