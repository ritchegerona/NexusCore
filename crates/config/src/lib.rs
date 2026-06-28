pub mod settings;

use crate::settings::NexusConfig;
use common::NexusResult;
use std::fs;

pub fn load_config(path: &str) -> NexusResult<NexusConfig> {
    let content = fs::read_to_string(path)
        .map_err(|e| common::NexusError::Config(format!("Failed to read '{}': {}", path, e)))?;

    let config: NexusConfig = toml::from_str(&content)
        .map_err(|e| common::NexusError::Config(format!("Failed to parse TOML: {}", e)))?;

    Ok(config)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = NexusConfig::default();
        assert_eq!(config.app_name, "NexusCore");
        assert_eq!(config.log_level, "info");
        assert_eq!(config.max_workers, Some(4));
    }

    #[test]
    fn test_load_config_missing_file() {
        let result = load_config("nonexistent.toml");
        assert!(result.is_err());
    }

    #[test]
    fn test_load_valid_config() {
        let test_toml = r#"
            app_name = "TestApp"
            log_level = "debug"
            max_workers = 16
        "#;
        std::fs::write("test_config.toml", test_toml).unwrap();

        let config = load_config("test_config.toml").unwrap();
        assert_eq!(config.app_name, "TestApp");
        assert_eq!(config.log_level, "debug");
        assert_eq!(config.max_workers, Some(16));

        std::fs::remove_file("test_config.toml").unwrap();
    }
}
