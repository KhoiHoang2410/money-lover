# External price fetch for valuation

To value multi-currency Accounts and Holdings in the base currency (VND), the app fetches live prices from three third-party endpoints rather than requiring all-manual entry:

- **FX (SGD/USD→VND):** `https://open.er-api.com/v6/latest/{BASE}`, read `rates.VND`. Official, free, no key, ~daily refresh — cache 24h.
- **SJC gold:** `https://edge-api.pnj.io/ecom-frontend/v1/get-gold-price?zone=00`, filter `masp=="SJC"`; `giaban`/`giamua` are in thousand-VND per chỉ (×1000 for VND/chỉ, ×10 for VND/lượng).
- **HOSE stock:** `https://dchart-api.vndirect.com.vn/dchart/history?symbol={TICKER}&resolution=D&from=&to=`, last `c[]` value, in thousand-VND (×1000).

All three were live-tested and reachable from a plain HTTPS client. Only the FX source is official/documented; the PNJ gold and VNDirect stock endpoints are vendor-run but **undocumented/reverse-engineered and will break eventually**.

## Consequences

- Every fetched price is cached as last-known. On fetch failure the app shows the cached value with a "stale" badge.
- **Manual price/rate override is mandatory and always available** — it is the permanent fallback when the unofficial endpoints break, not an afterthought.
- Fetch on app-foreground / pull-to-refresh only (not polling) to avoid rate-limiting the unofficial endpoints.
