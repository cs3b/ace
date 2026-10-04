# Frozen consumer dependency proof

Manifest package ace-task records `runtime_dependencies: {"ace-git-github": ["~> 0.4"]}` from its release source. With provider0.4.0, a consumer-only install declaring ~>0.4 passes edge verification. An installed ~>0.1 declaration refuses despite allowing0.4.0, because it differs from the frozen contract. Missing/empty dependency metadata fails; no historical ~>0.2 fallback is used. Freeze a new manifest for rerun; never amend an earlier failed run input.
