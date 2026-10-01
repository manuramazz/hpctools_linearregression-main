#include <stdlib.h>
#include <math.h>
#include "gaussian.h"

/* -------------------------------------------------------------------------
 * TODO (STUDENT): gaussian_elimination_solve
 *
 * Solve the p x p system:
 *
 *   XtX * beta = Xty
 *
 * using Gaussian elimination with partial pivoting, followed by back
 * substitution:
 *
 *   1. Build an augmented p x (p+1) matrix [XtX | Xty] (work on a local
 *      copy — do not modify XtX/Xty in place, you may want to keep them
 *      for the report).
 *   2. Forward elimination: for each pivot column k = 0..p-1,
 *        a. partial pivoting: find the row r >= k with the largest
 *           absolute value in column k, and swap rows k and r if r != k
 *           (this avoids dividing by a very small/zero pivot).
 *        b. eliminate column k from all rows below k by subtracting an
 *           appropriate multiple of row k.
 *   3. Back substitution: once the augmented matrix is in upper
 *      triangular form, solve for beta[p-1], beta[p-2], ..., beta[0]
 *      from the bottom row upward.
 *
 * XtX  : p x p, row-major (read-only)
 * Xty  : p (right-hand side, read-only)
 * beta : p (output, caller-allocated)
 * ---------------------------------------------------------------------- */
void gaussian_elimination_solve(const double *XtX, const double *Xty,
                                double *beta, int p) {

  /* TODO: implement Gaussian elimination with partial pivoting +
   * back substitution here. A scratch p x (p+1) augmented matrix can be
   * allocated locally with malloc and freed before returning.
   */
   double *augmented_matrix = (double *) malloc(p * (p + 1) * sizeof(double));
   
   for (int i = 0; i < p; i++) {
     for (int j = 0; j < p; j++) {
       augmented_matrix[i * (p + 1) + j] = XtX[i * p + j];
     }
     augmented_matrix[i * (p + 1) + p] = Xty[i];
   }
   // Forward elimination with partial pivoting
   for (int k=0; k<p-1; k++) {
      // Find the pivot row
      int pivot_row = k;
      for (int i=k+1; i<p; i++) {
         if (fabs(augmented_matrix[i * (p + 1) + k]) > fabs(augmented_matrix[pivot_row * (p + 1) + k])) {
            pivot_row = i;
         }
      }
      // Swap rows if necessary
      if (pivot_row != k) {
         for (int j=0; j<p+1; j++) {
            double temp = augmented_matrix[k * (p + 1) + j];
            augmented_matrix[k * (p + 1) + j] = augmented_matrix[pivot_row * (p + 1) + j];
            augmented_matrix[pivot_row * (p + 1) + j] = temp;
         }
      }
      // Eliminate column k from rows below
      for (int i=k+1; i<p; i++) {
         double factor = augmented_matrix[i * (p + 1) + k] / augmented_matrix[k * (p + 1) + k];
         for (int j=k; j<p+1; j++) {
            augmented_matrix[i * (p + 1) + j] -= factor * augmented_matrix[k * (p + 1) + j];
         }
      }
   }

   // Back substitution
   for(int i=p-1; i>=0; i--) {
      beta[i] = augmented_matrix[i * (p + 1) + p];
      for(int j=i+1; j<p; j++) {
         beta[i] -= augmented_matrix[i * (p + 1) + j] * beta[j];
      }
      beta[i] /= augmented_matrix[i * (p + 1) + i];
   }

   // Free the allocated memory for the augmented matrix
   free(augmented_matrix);
   

}


void gauss_jordan_solve(const double *XtX, const double *Xty,
                                double *beta, int p) {
   double *augmented_matrix = (double *) malloc(p * (p + 1) * sizeof(double));

   for (int i = 0; i < p; i++) {
      for (int j = 0; j < p; j++) {
         augmented_matrix[i * (p + 1) + j] = XtX[i * p + j];
      }
      augmented_matrix[i * (p + 1) + p] = Xty[i];
   }

   // Elimination with partial pivoting
   for (int k=0; k<p; k++) {
      // Find the pivot row
      int pivot_row = k;
      for (int i=k+1; i<p; i++) {
         if (fabs(augmented_matrix[i * (p + 1) + k]) > fabs(augmented_matrix[pivot_row * (p + 1) + k])) {
            pivot_row = i;
         }
      }
      // Swap rows if necessary
      if (pivot_row != k) {
         for (int j=0; j<p+1; j++) {
            double temp = augmented_matrix[k * (p + 1) + j];
            augmented_matrix[k * (p + 1) + j] = augmented_matrix[pivot_row * (p + 1) + j];
            augmented_matrix[pivot_row * (p + 1) + j] = temp;
         }
      }
      // Eliminate column k from all other rows
      for(int i=0; i<p; i++) {
         if(i != k) {
            double factor = augmented_matrix[i * (p + 1) + k] / augmented_matrix[k * (p + 1) + k];
            for(int j=k; j<p+1; j++) {
               augmented_matrix[i * (p + 1) + j] -= factor * augmented_matrix[k * (p + 1) + j];
            }
         }
      }
   }

   // The matrix is now diagonal: read the solution off the last column
   for (int i=0; i<p; i++) {
      beta[i] = augmented_matrix[i * (p + 1) + p] / augmented_matrix[i * (p + 1) + i];
   }

   // Free the allocated memory for the augmented matrix
   free(augmented_matrix);
}



