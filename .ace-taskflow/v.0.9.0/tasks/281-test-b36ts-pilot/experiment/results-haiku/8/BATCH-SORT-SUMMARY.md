# Goal 8: Batch Sort Order — Summary

## Test Setup

**Dates encoded (in specified non-chronological order)**:
1. 2025-12-31 (future)
2. 2015-03-10 (old)
3. 2030-07-20 (far future)
4. 2010-01-05 (very old)
5. 2022-11-15 (recent past)

## Results

### Original Encode Order
```
8nu000  # 2025-12-31
529000  # 2015-03-10
a6iyi0  # 2030-07-20
3c4000  # 2010-01-05
7me000  # 2022-11-15
```

### Lexicographic Sort Order
```
3c4000  # 2010-01-05
529000  # 2015-03-10
7me000  # 2022-11-15
8nu000  # 2025-12-31
a6iyi0  # 2030-07-20
```

## Key Observations

1. **Chronological Ordering Preserved**: The lexicographic sort of encoded tokens produces **chronological order** of the original dates
   - This is by design — base-36 encoding preserves temporal ordering
   - Token values increase monotonically with time

2. **No Collisions**: Each date produces a unique, reproducible token

3. **Sort Stability**: Standard `sort` command correctly orders tokens lexicographically

4. **Format Consistency**: All tokens in this batch are 6 characters (consistent with day-level granularity for these date ranges)

## Implications

This demonstrates that ace-b36ts tokens can be:
- **Sorted for retrieval** without decoding (lexicographic sort = time-ordered)
- **Used as reliable temporal IDs** in databases or indices
- **Compared directly** without decoding (token1 < token2 → date1 < date2)

## Files Generated

- `encoded-order.txt` — Tokens in the order they were encoded
- `sorted-order.txt` — Tokens sorted lexicographically (which is also chronological order)
