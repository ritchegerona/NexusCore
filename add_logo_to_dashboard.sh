#!/usr/bin/env bash
set -e

echo "🎨 Adding NexusCore logo to dashboard..."

# Create assets directory if not exists
mkdir -p crates/dashboard/static/assets

# Note: You'll need to save the logo image as logo.png in the assets folder
# For now, let's update the HTML to reference the logo

cat > crates/dashboard/static/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexusCore Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body class="bg-gray-900 text-white min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <header class="mb-8 text-center">
            <div class="flex flex-col items-center justify-center mb-6">
                <img src="/assets/logo.png" alt="NexusCore Logo" class="w-48 h-48 mb-4">
                <h1 class="text-5xl font-bold bg-gradient-to-r from-blue-400 to-cyan-300 bg-clip-text text-transparent">
                    NEXUSCORE
                </h1>
                <p class="text-gray-400 mt-2 text-lg tracking-wider">AGENTS. CONNECT. CREATE.</p>
            </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700 hover:border-blue-500 transition-all">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Status</p>
                        <p class="text-2xl font-bold text-green-400">Running</p>
                    </div>
                    <i data-lucide="activity" class="w-8 h-8 text-green-400"></i>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700 hover:border-blue-500 transition-all">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Crates</p>
                        <p class="text-2xl font-bold text-blue-400">6</p>
                    </div>
                    <i data-lucide="package" class="w-8 h-8 text-blue-400"></i>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700 hover:border-blue-500 transition-all">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Version</p>
                        <p class="text-2xl font-bold text-purple-400">0.1.0</p>
                    </div>
                    <i data-lucide="tag" class="w-8 h-8 text-purple-400"></i>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <h2 class="text-xl font-bold mb-4 text-blue-400">Quick Actions</h2>
                <div class="space-y-3">
                    <button class="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 px-4 py-3 rounded-lg text-left font-medium transition-all transform hover:scale-105 shadow-lg">
                        📦 Build Workspace
                    </button>
                    <button class="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 px-4 py-3 rounded-lg text-left font-medium transition-all transform hover:scale-105 shadow-lg">
                        🧪 Run Tests
                    </button>
                    <button class="w-full bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 px-4 py-3 rounded-lg text-left font-medium transition-all transform hover:scale-105 shadow-lg">
                        📊 View Documentation
                    </button>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <h2 class="text-xl font-bold mb-4 text-cyan-400">System Info</h2>
                <div class="space-y-3 text-sm">
                    <div class="flex justify-between items-center p-2 bg-gray-700 rounded">
                        <span class="text-gray-400">Rust Edition:</span>
                        <span class="font-mono text-cyan-300">2021</span>
                    </div>
                    <div class="flex justify-between items-center p-2 bg-gray-700 rounded">
                        <span class="text-gray-400">Workspace:</span>
                        <span class="font-mono text-green-300">Active</span>
                    </div>
                    <div class="flex justify-between items-center p-2 bg-gray-700 rounded">
                        <span class="text-gray-400">Async Runtime:</span>
                        <span class="font-mono text-blue-300">Tokio</span>
                    </div>
                    <div class="flex justify-between items-center p-2 bg-gray-700 rounded">
                        <span class="text-gray-400">Web Framework:</span>
                        <span class="font-mono text-purple-300">Axum</span>
                    </div>
                </div>
            </div>
        </div>

        <footer class="mt-8 text-center text-gray-500 text-sm">
            <p>Powered by NexusCore • Modular Rust Workspace Framework</p>
        </footer>
    </div>

    <script>
        lucide.createIcons();
    </script>
</body>
</html>
EOF

echo "✅ Dashboard HTML updated with logo placeholder!"
echo ""
echo "📝 Next step: Save your logo image as 'logo.png' in:"
echo "   crates/dashboard/static/assets/logo.png"
echo ""
echo "Then restart the dashboard to see the changes!"