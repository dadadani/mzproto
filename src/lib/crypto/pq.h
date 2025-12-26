#ifndef PQ_H
#define PQ_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __UINT64_TYPE__
typedef unsigned long long uint64_t;
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
#else
typedef __UINT64_TYPE__ uint64_t;
typedef __UINT32_TYPE__ uint32_t;
typedef __UINT16_TYPE__ uint16_t;
typedef __UINT8_TYPE__ uint8_t;
#endif

/*
 * Factor a 64-bit semiprime into two primes.
 * 
 * Parameters:
 *   n  - The semiprime to factor (product of two primes)
 *   p  - Output: smaller prime factor
 *   q  - Output: larger prime factor
 * 
 * Returns:
 *   1 on success (factors found, p * q == n)
 *   0 on failure (n <= 1, n is prime, or factorization failed)
 * 
 */
int pq_factor(uint64_t n, uint64_t *p, uint64_t *q);

/*
 * Seed the internal PRNG (optional).
 * Call this if you need deterministic results or want to vary the random state.
 * Default seed is 0xdeadbeefcafebabe.
 */
void pq_seed(uint64_t seed);

/*
 * Get the smaller factor directly (alternative API).
 * Returns 0 if factorization fails.
 */
uint64_t pq_factorize(uint64_t n);

#ifdef __cplusplus
}
#endif

#endif /* PQ_H */

