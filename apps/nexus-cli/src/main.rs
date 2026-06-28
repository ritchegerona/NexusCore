use clap::{Parser, Subcommand};
use logger::init_logger;
use workspace::Workspace;
use dialoguer::{theme::ColorfulTheme, Select, Input};
use console::style;

mod async_demo;

#[derive(Parser)]
#[command(name = "nexus-cli")]
#[command(about = "NexusCore CLI - A modular Rust workspace framework", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new workspace
    Init {
        #[arg(short, long)]
        name: Option<String>,
        #[arg(short, long, default_value = ".")]
        path: String,
    },
    Build {
        #[arg(short, long)]
        release: bool,
    },
    Test {
        #[arg(short, long)]
        verbose: bool,
    },
    Info,
    Interactive,
    /// Run async demonstration
    AsyncDemo,
}

fn main() {
    if let Err(e) = init_logger("info") {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init { name, path }) => handle_init(name, path),
        Some(Commands::Build { release }) => handle_build(release),
        Some(Commands::Test { verbose }) => handle_test(verbose),
        Some(Commands::Info) => handle_info(),
        Some(Commands::Interactive) => handle_interactive(),
        Some(Commands::AsyncDemo) => {
            let rt = tokio::runtime::Runtime::new().unwrap();
            rt.block_on(async {
                if let Err(e) = async_demo::run_async_demo().await {
                    tracing::error!("Async demo failed: {}", e);
                    std::process::exit(1);
                }
            });
        }
        None => {
            tracing::info!("Welcome to NexusCore CLI!");
            println!("Run {} for usage information.", style("nexus-cli --help").cyan());
        }
    }
}

fn handle_init(name: Option<String>, path: String) {
    let workspace_name = name.unwrap_or_else(|| {
        Input::with_theme(&ColorfulTheme::default())
            .with_prompt("Workspace name")
            .default("my-workspace".into())
            .interact_text()
            .unwrap()
    });

    tracing::info!("Initializing workspace '{}' at '{}'...", workspace_name, path);
    
    match Workspace::new(&workspace_name, &path) {
        Ok(ws) => {
            let config_path = format!("{}/workspace.json", path);
            if let Err(e) = ws.save(&config_path) {
                tracing::error!("Failed to save workspace config: {}", e);
                std::process::exit(1);
            }
            
            println!("{}", style("✓ Workspace created successfully!").green());
            println!("  Name: {}", ws.name);
            println!("  Path: {}", ws.path.display());
        }
        Err(e) => {
            tracing::error!("Failed to create workspace: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_build(release: bool) {
    let mode = if release { "release" } else { "debug" };
    tracing::info!("Building workspace in {} mode...", mode);
    
    let status = if release {
        std::process::Command::new("cargo")
            .args(["build", "--release", "--workspace"])
            .status()
    } else {
        std::process::Command::new("cargo")
            .args(["build", "--workspace"])
            .status()
    };

    match status {
        Ok(s) if s.success() => {
            println!("{}", style("✓ Build completed successfully!").green());
        }
        Ok(s) => {
            tracing::error!("Build failed with status: {}", s);
            std::process::exit(1);
        }
        Err(e) => {
            tracing::error!("Failed to execute build: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_test(verbose: bool) {
    tracing::info!("Running tests...");
    
    let mut cmd = std::process::Command::new("cargo");
    cmd.args(["test", "--workspace"]);
    
    if verbose {
        cmd.arg("--verbose");
    }

    match cmd.status() {
        Ok(s) if s.success() => {
            println!("{}", style("✓ All tests passed!").green());
        }
        Ok(s) => {
            tracing::error!("Tests failed with status: {}", s);
            std::process::exit(1);
        }
        Err(e) => {
            tracing::error!("Failed to execute tests: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_info() {
    println!("{}", style("NexusCore Workspace Information").cyan().bold());
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    
    match config::load_config("nexus.toml") {
        Ok(cfg) => {
            println!("Application: {}", cfg.app_name);
            println!("Log Level:   {}", cfg.log_level);
            println!("Max Workers: {:?}", cfg.max_workers.unwrap_or(4));
        }
        Err(_) => {
            println!("Configuration: Not found (using defaults)");
        }
    }
    
    println!("\nCrates:");
    println!("  • common        - Shared types and utilities");
    println!("  • config        - Configuration management");
    println!("  • logger        - Structured logging");
    println!("  • filesystem    - File operations");
    println!("  • workspace     - Workspace management");
    println!("  • async-runtime - Async operations & HTTP client");
}

fn handle_interactive() {
    println!("{}", style("NexusCore Interactive Mode").cyan().bold());
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    
    let options = vec![
        "Initialize workspace",
        "Build project",
        "Run tests",
        "Show info",
        "Run async demo",
        "Exit"
    ];
    
    let selection = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("What would you like to do?")
        .items(&options)
        .default(0)
        .interact()
        .unwrap();

    match selection {
        0 => handle_init(None, ".".to_string()),
        1 => handle_build(false),
        2 => handle_test(false),
        3 => handle_info(),
        4 => {
            let rt = tokio::runtime::Runtime::new().unwrap();
            rt.block_on(async {
                if let Err(e) = async_demo::run_async_demo().await {
                    tracing::error!("Async demo failed: {}", e);
                }
            });
        }
        5 => {
            println!("{}", style("Goodbye!").green());
            std::process::exit(0);
        }
        _ => unreachable!(),
    }
}
