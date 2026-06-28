use common::{NexusError, NexusResult};
use tracing_subscriber::{fmt, EnvFilter};

pub fn init_logger(log_level: &str) -> NexusResult<()> {
    let filter = EnvFilter::try_new(log_level)
        .map_err(|e| NexusError::Config(format!("Invalid log level '{}': {}", log_level, e)))?;

    fmt().with_env_filter(filter).with_target(false).init();

    tracing::info!("Logger initialized successfully.");
    Ok(())
}
