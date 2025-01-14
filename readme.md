# PyO3 DuckDB pyarrow Windows Issue

The following example reproduces an issue with PyO3, DuckDB, and pyarrow on Windows. The issue is related to the import order of a custom PyO3 module with bundled duckdb (`pyo3_duckdb_pyarrow`) and the `pyarrow` module.

Tne problem only occurs on Windows. The code works on Linux.

## Issue description

The issue is related to the import order of `pyo3_duckdb_pyarrow` module and `pyarrow`. If the `pyarrow` module is imported before `pyo3_duckdb_pyarrow`, the following error occurs on the run method of the `pyo3_duckdb_pyarrow` module:
```
thread '<unnamed>' panicked at C:\Users\ContainerAdministrator\.cargo\registry\src\index.crates.io-6f17d22bba15001f\duckdb-1.1.1\src\config.rs:127:13:
assertion `left == right` failed
  left: 1
 right: 0
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
Traceback (most recent call last):
  File "C:\app\test.py", line 4, in <module>
    pyo3_duckdb_pyarrow.run()
pyo3_runtime.PanicException: assertion `left == right` failed
  left: 1
 right: 0
The command 'cmd /S /C .venv\Scripts\activate.bat && python test.py' returned a non-zero code: 1
```

The referred code is from the [DuckDB crate](https://github.com/duckdb/duckdb-rs/blob/2bd811e7b1b7398c4f461de4de263e629572dc90/crates/duckdb/src/config.rs#L127):
```rust
fn set(&mut self, key: &str, value: &str) -> Result<()> {
    if self.config.is_none() {
        let mut config: ffi::duckdb_config = ptr::null_mut();
        let state = unsafe { ffi::duckdb_create_config(&mut config) };
        assert_eq!(state, ffi::DuckDBSuccess);
        self.config = Some(config);
    }
    ...
}
```

The `assert_eq!(state, ffi::DuckDBSuccess);` lines fails because `let state = unsafe { ffi::duckdb_create_config(&mut config) };` returns `ffi::DuckDBError`.  

According to the documentation of (see [here](https://github.com/duckdb/duckdb-rs/blob/2bd811e7b1b7398c4f461de4de263e629572dc90/crates/libduckdb-sys/src/bindgen_bundled_version.rs#L2486)) this only can fail due to malloc issues: `... This will always succeed unless there is a malloc failure. ...`

**I am not sure if the issue is strictly PyO3 related or maybe DuckDB, pyarrow, Python or Rust or the combination of those are causing the issue.**

### Works

If the module is loaded before `pyarrow` it works (see `test-works.py`):
```python
import pyo3_duckdb_pyarrow
import pyarrow

pyo3_duckdb_pyarrow.run()
```

### Fails

If the module is loaded after `pyarrow` it fails (see `test-fails.py`):
```python
import pyarrow
import pyo3_duckdb_pyarrow

pyo3_duckdb_pyarrow.run()
```

## Reproduce the issue

Build the provided Windows Container with Docker: 
```
docker build -t reproduce-issue .
```

**It is important to use [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce).**

## Versions

The container installs the following versions:
- Install Python 3.12.8
- Latest VS Build Tools (https://aka.ms/vs/17/release/vs_BuildTools.exe):
  - Microsoft.VisualStudio.Component.Windows10SDK.18362
- Latest Rust wit Rustup
- Python packages:
  - pyarrow==18.1.0
  - maturin==1.8.1
- Rust dependencies:
  - pyo3: 0.23.4
  - duckdb: 1.1.1

## Additional notes
- The issue cannot be reproduced on my home computer, but it can be reproduced on my work computer and in the provided container.
- Original issue found with PyO3 `0.22.6`, but could be reproduced with `0.23.4`.
- Reproduced with Python `3.10.11`, `3.12.8` and `3.13.1`.
- Reproduced with MVSC `Microsoft.VisualStudio.Component.Windows11SDK.22000` and `Microsoft.VisualStudio.Component.Windows10SDK.18362`.
- Reproduced with PyO3 Feature `abi3-py311` and `abi3-py38`.
- Reproduced with Docker base image `mcr.microsoft.com/windows/servercore:ltsc2022` and `mcr.microsoft.com/windows:ltsc2019`.