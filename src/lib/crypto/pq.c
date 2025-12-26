#include "pq.h"

typedef unsigned __int128 u128;
typedef uint64_t u64;
typedef uint32_t u32;

static u64 pq_rng_state = 0xdeadbeefcafebabeULL;

void pq_seed(u64 seed) {
    pq_rng_state = seed ? seed : 0xdeadbeefcafebabeULL;
}

static inline u64 rand64(void) {
    u64 x = pq_rng_state;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    pq_rng_state = x;
    return x * 0x2545f4914f6cdd1dULL;
}


static inline __attribute__((always_inline)) u64 gcd(u64 a, u64 b) {
    if (!a) return b;
    if (!b) return a;
    
    /* Common factors of 2 */
    int shift = __builtin_ctzll(a | b);
    a >>= __builtin_ctzll(a);
    
    do {
        b >>= __builtin_ctzll(b);
        if (a > b) {
            u64 t = a;
            a = b;
            b = t;
        }
        b -= a;
    } while (b);
    
    return a << shift;
}

typedef struct {
    u64 n;      /* modulus */
    u64 ninv;   /* -n^(-1) mod 2^64 */
    u64 r2;     /* R^2 mod n, where R = 2^64 */
} Mont;

/* Compute -n^(-1) mod 2^64 via Newton iteration */
static inline u64 mont_inv(u64 n) {
    u64 x = n;
    x *= 2 - n * x;
    x *= 2 - n * x;
    x *= 2 - n * x;
    x *= 2 - n * x;
    x *= 2 - n * x;
    return -x;
}

static inline u64 mod128(u128 a, u64 n) {
    if (a < n) return (u64)a;
    
    /* Find highest bit position */
    u128 q = n;
    int shift = 0;
    while (q <= a >> 1) {
        q <<= 1;
        shift++;
    }
    
    /* Long division */
    while (shift >= 0) {
        if (a >= q) {
            a -= q;
        }
        q >>= 1;
        shift--;
    }
    
    return (u64)a;
}

static inline void mont_init(Mont *m, u64 n) {
    m->n = n;
    m->ninv = mont_inv(n);
    /* Compute R^2 mod n where R = 2^64 */
    /* R mod n = 2^64 mod n = -n mod 2^64 mod n = (0 - n) mod n when computed correctly */
    /* We compute 2^64 mod n by noting that 2^64 = 2^64 - n*k for appropriate k */
    u128 r = ((u128)1 << 64);
    u64 r_mod_n = mod128(r, n);
    u64 r2_mod_n = mod128((u128)r_mod_n * r_mod_n, n);
    m->r2 = r2_mod_n;
}

/* Montgomery reduction: (a * R^(-1)) mod n */
static inline __attribute__((always_inline)) u64 mont_redc(const Mont *m, u128 a) {
    u64 t = (u64)a * m->ninv;
    u128 s = a + (u128)t * m->n;
    u64 r = s >> 64;
    return r >= m->n ? r - m->n : r;
}

/* Convert to Montgomery form: a -> aR mod n */
static inline u64 to_mont(const Mont *m, u64 a) {
    return mont_redc(m, (u128)a * m->r2);
}

/* Convert from Montgomery form: aR -> a */
static inline u64 from_mont(const Mont *m, u64 a) {
    return mont_redc(m, a);
}

/* Montgomery multiplication: (aR * bR) -> abR mod n */
static inline __attribute__((always_inline)) u64 mont_mul(const Mont *m, u64 a, u64 b) {
    return mont_redc(m, (u128)a * b);
}

/* Montgomery subtraction with wrap-around handling */
static inline __attribute__((always_inline)) u64 mont_sub(const Mont *m, u64 a, u64 b) {
    return a >= b ? a - b : a + m->n - b;
}

/* Montgomery addition */
static inline __attribute__((always_inline)) u64 mont_add(const Mont *m, u64 a, u64 b) {
    u64 s = a + b;
    return (s >= m->n || s < a) ? s - m->n : s;
}

/* Absolute difference in Montgomery space */
static inline __attribute__((always_inline)) u64 mont_absdiff(const Mont *m, u64 a, u64 b) {
    return a > b ? mont_sub(m, a, b) : mont_sub(m, b, a);
}

static u64 __attribute__((noinline)) rho(u64 n) {
    Mont m;
    mont_init(&m, n);
    
    /* Batch size for GCD - larger = fewer GCD calls but risk of overshoot */
    const u64 M = 512;
    
    for (int attempt = 0; attempt < 50; attempt++) {
        u64 y = to_mont(&m, (rand64() % (n - 1)) + 1);
        u64 c = to_mont(&m, (rand64() % (n - 1)) + 1);
        u64 one = to_mont(&m, 1);
        
        u64 g = 1, r = 1, q = one;
        u64 x, ys;
        
        while (g == 1) {
            x = y;
            
            /* Advance y by r steps */
            for (u64 i = 0; i < r; i++) {
                y = mont_add(&m, mont_mul(&m, y, y), c);
            }
            
            u64 k = 0;
            while (k < r && g == 1) {
                ys = y;
                u64 iters = M < (r - k) ? M : (r - k);
                
                /* Inner loop: stay entirely in Montgomery space */
                for (u64 i = 0; i < iters; i++) {
                    y = mont_add(&m, mont_mul(&m, y, y), c);
                    u64 d = mont_absdiff(&m, x, y);
                    if (d) q = mont_mul(&m, q, d);
                }
                
                /* Only convert when computing GCD */
                g = gcd(from_mont(&m, q), n);
                k += M;
            }
            
            r *= 2;
            if (r > 1000000) break;  /* Safety limit */
        }
        
        /* Backtrack if we overshot (g == n) */
        if (g == n) {
            g = 1;
            y = ys;
            while (g == 1) {
                y = mont_add(&m, mont_mul(&m, y, y), c);
                u64 d = mont_absdiff(&m, x, y);
                g = gcd(from_mont(&m, d), n);
            }
        }
        
        if (g > 1 && g < n) {
            return g;
        }
    }
    
    return 0;
}


static const uint16_t small_primes[] = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
    331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
    421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503
};

#define N_SMALL_PRIMES (sizeof(small_primes) / sizeof(small_primes[0]))

static inline u64 trial_division(u64 n) {
    for (u32 i = 0; i < N_SMALL_PRIMES; i++) {
        if (n % small_primes[i] == 0) {
            return small_primes[i];
        }
    }
    return 0;
}


u64 pq_factorize(u64 n) {
    if (n <= 1) return 0;
    
    u64 p = trial_division(n);
    if (p) {
        u64 q = n / p;
        return p < q ? p : q;
    }
    
    p = rho(n);
    if (p > 0 && p < n) {
        u64 q = n / p;
        return p < q ? p : q;
    }
    
    return 0;
}

int pq_factor(u64 n, u64 *p, u64 *q) {
    u64 factor = pq_factorize(n);
    
    if (factor == 0) {
        return 0;
    }
    
    u64 other = n / factor;
    
    /* Verify */
    if (factor * other != n) {
        return 0;
    }
    
    /* Return smaller factor in p */
    if (factor < other) {
        *p = factor;
        *q = other;
    } else {
        *p = other;
        *q = factor;
    }
    
    return 1;
}
