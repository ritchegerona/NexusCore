use thiserror::Error;

#[derive(Error, Debug)]
pub enum NexusError {
    #[error("Configuration error: {0}")]
    Config(String),

    #[error("Filesystem error: {0}")]
    Filesystem(#[from] std::io::Error),

    #[error("Unknown error: {0}")]
    Unknown(String),
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_error() {
        let err = NexusError::Config("test error".to_string());
        assert_eq!(format!("{}", err), "Configuration error: test error");
    }

    #[test]
    fn test_filesystem_error() {
        let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
        let err = NexusError::Filesystem(io_err);
        assert!(format!("{}", err).contains("Filesystem error"));
    }
}
