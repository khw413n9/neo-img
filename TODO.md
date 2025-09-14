# Neo-Img Backlog / Ideas

## Persistent / Streaming
- Unify backend interface (`render(args, config, emit)` + optional `start/stop`)
- Persistent process prototype (dummy -> ttyimg) with restart & health checks
- Progressive rendering (low-res first, then full) using staged cache keys

## Additional Engines
- ascii fallback (chafa / viu) engine for non-sixel / non-kitty terminals
- kitty direct protocol encoder (base64 chunks, id reuse) without external binary
- libsixel FFI path (optional high-perf build) with dynamic capability detection

## Capability Detection
- Expand auto engine: detect sixel support (terminfo / env) -> choose appropriate engine
- Detect absence of wezterm binary even if TERM_PROGRAM indicates WezTerm

## Caching Improvements
- Separate placement cache vs geometry cache (current change foundations laid)
- Add max items limit and adaptive eviction (frequency + recency)
- Optional persistent on-disk cache (hash(file+geometry) -> esc) with TTL

## Profiling & Debug UX
- Pretty table formatting for :NeoImg Debug (aligned columns, durations between events)
- Configurable profiler buffer size (current fixed ring length)
- Event: persistent_reuse / persistent_restart / progressive_stage

## Error Handling
- Standardize backend error reporting (exit code, stderr capture) aggregated to render_error
- Retry logic for transient failures (e.g., race on window size collection)

## Geometry / Layout
- Option to center via kitty image placement (when kitty direct implemented)
- Smart reflow on window resize: only re-draw if geometry scale changed > threshold

## Testing / CI
- Minimal busted tests for cache key generation & eviction
- Golden output tests for dummy and ascii engines

## Documentation
- Add architecture diagram (state flow: event -> debounce -> backend -> draw)
- Comparison table of engines (features, protocols, perf expectations)

## Future Nice-to-Haves
- Animated GIF multi-frame support (progressive swap) with frame cache
- Async cancellation when user switches buffer rapidly (debounce collapse)
- User command: :NeoImg ClearCache

(Generated backlog - update as features land.)
