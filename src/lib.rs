use pyo3::pymodule;

#[pymodule]
mod pyo3_duckdb_pyarrow {
    use pyo3::pyfunction;
    use duckdb::DuckdbConnectionManager;

    #[pyfunction]
    fn run() {
        let pool = DuckdbConnectionManager::memory();
        println!("Connection pool created: {}", pool.is_ok());
    }
}