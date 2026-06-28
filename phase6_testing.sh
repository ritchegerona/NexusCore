#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 6: Testing & Quality Assurance..."

# --- COMMON CRATE TESTS ---
echo "🧪 Adding tests to 'common' crate..."
cat >> crates/common/src/error.rs <<EOF

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
EOF

# --- CONFIG CRATE TESTS ---
echo "🧪 Adding tests to 'config' crate..."
cat >> crates/config/src/lib.rs <<EOF

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
EOF

# --- FILESYSTEM CRATE TESTS ---
echo "🧪 Adding tests to 'filesystem' crate..."
cat >> crates/filesystem/src/operations.rs <<EOF

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_write_and_read_file() {
        let test_path = "test_file.txt";
        let content = "test content";
        
        write_file(test_path, content).unwrap();
        let read_content = read_file(test_path).unwrap();
        
        assert_eq!(content, read_content);
        fs::remove_file(test_path).unwrap();
    }

    #[test]
    fn test_create_dir() {
        let test_dir = "test_dir";
        create_dir(test_dir).unwrap();
        
        assert!(file_exists(test_dir));
        fs::remove_dir(test_dir).unwrap();
    }

    #[test]
    fn test_file_exists() {
        let test_path = "exists_test.txt";
        assert!(!file_exists(test_path));
        
        fs::write(test_path, "test").unwrap();
        assert!(file_exists(test_path));
        
        fs::remove_file(test_path).unwrap();
    }

    #[test]
    fn test_read_nonexistent_file() {
        let result = read_file("nonexistent.txt");
        assert!(result.is_err());
    }
}
EOF

# --- WORKSPACE CRATE TESTS ---
echo "🧪 Adding tests to 'workspace' crate..."
cat >> crates/workspace/src/manager.rs <<EOF

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_workspace_creation() {
        let test_path = "test_workspace";
        let ws = Workspace::new("test-ws", test_path).unwrap();
        
        assert_eq!(ws.name, "test-ws");
        assert!(file_exists(test_path));
        
        fs::remove_dir_all(test_path).unwrap();
    }

    #[test]
    fn test_workspace_save() {
        let test_path = "test_ws_save";
        let ws = Workspace::new("save-test", test_path).unwrap();
        
        let config_path = format!("{}/workspace.json", test_path);
        ws.save(&config_path).unwrap();
        
        assert!(file_exists(&config_path));
        
        fs::remove_dir_all(test_path).unwrap();
    }
}
EOF

# --- RUN ALL TESTS ---
echo "🏃 Running all tests..."
cargo test --workspace

echo ""
echo "========================================="
echo " ✅ Phase 6 Complete!"
echo "========================================="
echo " All crates now have comprehensive tests."
echo " Run 'cargo test' anytime to verify."