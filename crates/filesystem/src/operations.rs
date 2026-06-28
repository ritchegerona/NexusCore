use common::{NexusError, NexusResult};
use std::fs;
use std::path::Path;

pub fn read_file(path: &str) -> NexusResult<String> {
    tracing::debug!("Reading file: {}", path);
    fs::read_to_string(path).map_err(|e| {
        NexusError::Filesystem(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("Failed to read '{}': {}", path, e),
        ))
    })
}

pub fn write_file(path: &str, content: &str) -> NexusResult<()> {
    tracing::debug!("Writing file: {}", path);
    fs::write(path, content).map_err(|e| {
        NexusError::Filesystem(std::io::Error::other(format!(
            "Failed to write '{}': {}",
            path, e
        )))
    })
}

pub fn create_dir(path: &str) -> NexusResult<()> {
    tracing::debug!("Creating directory: {}", path);
    fs::create_dir_all(path).map_err(|e| {
        NexusError::Filesystem(std::io::Error::other(format!(
            "Failed to create directory '{}': {}",
            path, e
        )))
    })
}

pub fn file_exists(path: &str) -> bool {
    Path::new(path).exists()
}

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
