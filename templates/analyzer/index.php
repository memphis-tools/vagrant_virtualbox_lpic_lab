<?php
// ==================== BACKEND HANDLERS ==================== //

// Handle export request - serves raw log file for download
if (isset($_GET['export'])) {
    $logPath = '/mnt/data_encrypted/labs.log';
    if (!file_exists($logPath) || !is_readable($logPath)) {
        http_response_code(404);
        die('Log file not accessible');
    }
    header('Content-Type: text/plain');
    header('Content-Disposition: attachment; filename="labs_export_' . date('Y-m-d_H-i-s') . '.log"');
    header('Cache-Control: no-cache');
    readfile($logPath);
    exit;
}

// Handle poll request - returns updated log window HTML for AJAX
if (isset($_GET['poll'])) {
    header('Content-Type: text/html');
    header('Cache-Control: no-cache');

    $logPath = '/mnt/data_encrypted/labs.log';

    if (!file_exists($logPath) || !is_readable($logPath)) {
        echo '<div class="error-message visible">⚠ Log file not accessible</div>';
        exit;
    }

    $logContent = file_get_contents($logPath);
    $lines = explode("\n", trim($logContent));

    // Send line count header for comparison
    $validLines = array_filter($lines);
    header('X-Log-Line-Count: ' . count($validLines));

    foreach ($lines as $line) {
        if (trim($line) === '') continue;
        echo renderLogEntry($line);
    }
    exit;
}

// Helper function to render individual log entry (for AJAX responses)
function renderLogEntry($line) {
    $lineLower = strtolower($line);
    $severity = 'info';
    $tagClass = 'tag-info';

    if (strpos($lineLower, 'error') !== false || strpos($lineLower, 'failed') !== false || strpos($lineLower, 'fail') !== false) {
        $severity = 'error';
        $tagClass = 'tag-error';
    } elseif (strpos($lineLower, 'warning') !== false || strpos($lineLower, 'warn') !== false) {
        $severity = 'warning';
        $tagClass = 'tag-warning';
    } elseif (strpos($lineLower, 'success') !== false || strpos($lineLower, 'completed') !== false) {
        $severity = 'success';
        $tagClass = 'tag-success';
    }

    // Extract timestamp (assuming first 25 characters)
    $timestamp = htmlspecialchars(substr($line, 0, 25));
    $message = htmlspecialchars(substr($line, 25));

    return '
<div class="log-entry ' . $severity . '" data-severity="' . $severity . '">
    <span class="timestamp">' . $timestamp . '</span>
    <span class="severity-tag ' . $tagClass . '">' . strtoupper($severity) . '</span>
    <span class="log-message">' . $message . '</span>
</div>';
}

// ==================== LOAD LOG DATA ==================== //

// Load logs from the encrypted storage path
$logPath = '/mnt/data_encrypted/labs.log';
$logContent = '';
$errorMsg = '';
$lineCount = 0;
$filterPattern = isset($_GET['filter']) ? $_GET['filter'] : '';
$sortOrder = isset($_GET['sort']) ? $_GET['sort'] : 'desc'; // desc = recent first
$dateFrom = isset($_GET['date_from']) ? $_GET['date_from'] : '';
$dateTo = isset($_GET['date_to']) ? $_GET['date_to'] : '';

if (!file_exists($logPath)) {
    $errorMsg = 'Log file not found at ' . htmlspecialchars($logPath);
} elseif (!is_readable($logPath)) {
    $errorMsg = 'Unable to read log file (check permissions)';
} else {
    $logContent = file_get_contents($logPath);
    $lines = explode("\n", trim($logContent));
    $allLines = array_values(array_filter($lines));

    // Apply filters
    $filteredLines = [];
    foreach ($allLines as $line) {
        $lineTrimmed = trim($line);
        if ($lineTrimmed === '') continue;

        // Apply text filter
        if ($filterPattern && stripos($lineTrimmed, $filterPattern) === false) {
            continue;
        }

        // Apply date range filter (assuming timestamp format at start of line)
        $lineTimestamp = substr($lineTrimmed, 0, 25);
        if ($dateFrom || $dateTo) {
            $lineDate = date('Y-m-d', strtotime($lineTimestamp));
            if ($dateFrom && $lineDate < $dateFrom) continue;
            if ($dateTo && $lineDate > $dateTo) continue;
        }

        $filteredLines[] = $lineTrimmed;
    }

    // Sort lines based on user preference
    if ($sortOrder === 'asc') {
        sort($filteredLines); // Oldest first
    } else {
        rsort($filteredLines); // Most recent first (default)
    }

    $lineCount = count($filteredLines);
    $logContent = implode("\n", $filteredLines);
    $lines = $filteredLines;
}

// Pagination setup - max 25 entries per page
$itemsPerPage = 25;
$currentPage = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
$totalPages = ceil(count($lines) / $itemsPerPage);
$startIndex = ($currentPage - 1) * $itemsPerPage;
$endIndex = min($startIndex + $itemsPerPage, count($lines));
$paginatedLines = array_slice($lines, $startIndex, $itemsPerPage);
$pageEnd = $endIndex;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>LAB ANALYZER</title>
    <style>
        /* === RESET & BASE === */
        *, *::before, *::after {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --primary-color: #6d4aff;
            --secondary-color: #a88bff;
            --accent-color: #00d4ff;
            --bg-dark: #0a0a0f;
            --bg-panel: #12121a;
            --text-primary: #ffffff;
            --text-secondary: #8b8b9e;
            --success-color: #00ff88;
            --warning-color: #ffaa00;
            --danger-color: #ff4466;
            --font-mono: 'SF Mono', 'Consolas', 'Monaco', 'Cascadia Code', monospace;
            --font-sans: 'Segoe UI', system-ui, sans-serif;
            --transition-speed: 0.3s;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            font-family: var(--font-sans);
            background: var(--bg-dark);
            color: var(--text-primary);
            overflow-x: hidden;
            scroll-padding-top: 0;
        }

        /* === FULL SCREEN SECTIONS === */
        .section {
            min-height: 100vh;
            width: 100%;
            position: relative;
            overflow: hidden;
        }

        /* === SECTION 1: HERO WITH CENTERED TEXT === */
        .hero-section {
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, var(--bg-dark) 0%, #1a1a2e 50%, #0a0a0f 100%);
        }

        /* Animated grid background effect */
        .hero-bg {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-image:
                linear-gradient(rgba(109, 74, 255, 0.03) 1px, transparent 1px),
                linear-gradient(90deg, rgba(109, 74, 255, 0.03) 1px, transparent 1px);
            background-size: 50px 50px;
            animation: gridMove 20s linear infinite;
            z-index: 0;
        }

        @keyframes gridMove {
            0% { transform: translate(0, 0); }
            100% { transform: translate(50px, 50px); }
        }

        /* Glowing particles overlay */
        .particles {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 1;
        }

        .particle {
            position: absolute;
            width: 2px;
            height: 2px;
            background: var(--accent-color);
            border-radius: 50%;
            animation: float 15s infinite ease-in-out;
            opacity: 0.6;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0) translateX(0); opacity: 0; }
            10% { opacity: 0.6; }
            90% { opacity: 0.6; }
            100% { transform: translateY(-100vh) translateX(50px); opacity: 0; }
        }

        .hero-content {
            position: relative;
            z-index: 10;
            text-align: center;
            max-width: 800px;
            padding: 2rem;
        }

        /* Decorative tech frame around logo */
        .tech-frame {
            position: relative;
            display: inline-block;
            padding: 3rem 5rem;
            border: 2px solid transparent;
            background:
                linear-gradient(var(--bg-dark), var(--bg-dark)) padding-box,
                linear-gradient(135deg, var(--primary-color), var(--accent-color)) border-box;
            border-radius: 12px;
            margin-bottom: 1.5rem;
        }

        .tech-frame::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            background: linear-gradient(135deg, var(--primary-color), var(--accent-color));
            border-radius: 12px;
            z-index: -1;
            opacity: 0.3;
            filter: blur(15px);
        }

        .logo-text {
            font-size: clamp(2.5rem, 8vw, 5rem);
            font-weight: 800;
            letter-spacing: 0.3em;
            background: linear-gradient(135deg, var(--text-primary) 0%, var(--primary-color) 50%, var(--accent-color) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            text-transform: uppercase;
            text-shadow: 0 0 40px rgba(109, 74, 255, 0.5);
            animation: glowPulse 3s ease-in-out infinite;
        }

        @keyframes glowPulse {
            0%, 100% { filter: drop-shadow(0 0 20px rgba(109, 74, 255, 0.3)); }
            50% { filter: drop-shadow(0 0 40px rgba(109, 74, 255, 0.6)); }
        }

        .subtext {
            font-family: var(--font-mono);
            color: var(--text-secondary);
            font-size: 1rem;
            letter-spacing: 0.2em;
            margin-top: 1rem;
            opacity: 0.7;
        }

        /* Scan line indicator */
        .scan-line {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--accent-color), transparent);
            animation: scan 4s ease-in-out infinite;
            z-index: 5;
            opacity: 0.5;
        }

        @keyframes scan {
            0%, 100% { top: 0; opacity: 0; }
            50% { top: 100%; opacity: 0.5; }
        }

        /* Scroll indicator */
        .scroll-indicator {
            position: absolute;
            bottom: 40px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 10;
            animation: bounce 2s infinite;
            cursor: pointer;
        }

        .scroll-arrow {
            width: 30px;
            height: 30px;
            border-right: 2px solid var(--primary-color);
            border-bottom: 2px solid var(--primary-color);
            transform: rotate(45deg);
        }

        @keyframes bounce {
            0%, 100% { transform: translateX(-50%) translateY(0); }
            50% { transform: translateX(-50%) translateY(15px); }
        }

        /* === SECTION 2: LOG DISPLAY === */
        .logs-section {
            display: flex;
            flex-direction: column;
            background: var(--bg-panel);
            padding: 2rem;
            position: relative;
        }

        .logs-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid rgba(109, 74, 255, 0.3);
        }

        .header-title {
            font-family: var(--font-mono);
            font-size: 1.2rem;
            color: var(--accent-color);
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            background: var(--success-color);
            border-radius: 50%;
            box-shadow: 0 0 10px var(--success-color);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { box-shadow: 0 0 10px var(--success-color); opacity: 1; }
            50% { box-shadow: 0 0 20px var(--success-color); opacity: 0.7; }
        }

        .header-actions {
            display: flex;
            gap: 0.5rem;
        }

        .header-actions button {
            background: rgba(109, 74, 255, 0.2);
            border: 1px solid var(--primary-color);
            color: var(--text-primary);
            padding: 0.5rem 1.2rem;
            border-radius: 6px;
            cursor: pointer;
            font-family: var(--font-mono);
            font-size: 0.85rem;
            transition: all var(--transition-speed);
            white-space: nowrap;
        }

        .header-actions button:hover:not(:disabled) {
            background: rgba(109, 74, 255, 0.3);
            box-shadow: 0 0 15px rgba(109, 74, 255, 0.4);
        }

        .header-actions button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: rgba(109, 74, 255, 0.1);
        }

        .header-actions button:not(:disabled):active {
            transform: scale(0.98);
        }

        .error-message {
            background: rgba(255, 68, 102, 0.1);
            border: 1px solid var(--danger-color);
            color: var(--danger-color);
            padding: 1rem 1.5rem;
            border-radius: 8px;
            font-family: var(--font-mono);
            margin-bottom: 1.5rem;
            display: none;
        }

        .error-message.visible {
            display: block;
            animation: fadeIn 0.5s;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Log container with terminal aesthetic */
        .log-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: rgba(10, 10, 15, 0.95);
            border: 1px solid rgba(109, 74, 255, 0.2);
            border-radius: 12px;
            overflow: hidden;
            position: relative;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
        }

        .log-container::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 30px;
            background: linear-gradient(180deg, rgba(109, 74, 255, 0.1), transparent);
            pointer-events: none;
        }

        /* Control bar - combines filter, sort, and pagination */
        .control-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 0.75rem;
            padding: 1rem;
            background: rgba(109, 74, 255, 0.05);
            border-bottom: 1px solid rgba(109, 74, 255, 0.2);
            flex-shrink: 0;
            align-items: center;
        }

        .control-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
            flex: 1;
            min-width: 200px;
        }

        .filter-input {
            flex: 1;
            min-width: 150px;
            background: rgba(10, 10, 15, 0.8);
            border: 1px solid rgba(109, 74, 255, 0.3);
            border-radius: 6px;
            padding: 0.5rem 1rem;
            color: var(--text-primary);
            font-family: var(--font-mono);
            font-size: 0.85rem;
            outline: none;
            transition: all var(--transition-speed);
        }

        .filter-input:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 10px rgba(109, 74, 255, 0.3);
        }

        .filter-input::placeholder {
            color: var(--text-secondary);
        }

        /* Date range inputs */
        .date-range-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .date-input {
            background: rgba(10, 10, 15, 0.8);
            border: 1px solid rgba(109, 74, 255, 0.3);
            border-radius: 6px;
            padding: 0.5rem;
            color: var(--text-primary);
            font-family: var(--font-mono);
            font-size: 0.8rem;
            outline: none;
            transition: all var(--transition-speed);
        }

        .date-input:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 10px rgba(109, 74, 255, 0.3);
        }

        /* Select dropdowns */
        .select-input {
            background: rgba(10, 10, 15, 0.8);
            border: 1px solid rgba(109, 74, 255, 0.3);
            border-radius: 6px;
            padding: 0.5rem 2rem 0.5rem 0.75rem;
            color: var(--text-primary);
            font-family: var(--font-mono);
            font-size: 0.85rem;
            outline: none;
            cursor: pointer;
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%236d4aff' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 0.75rem center;
            transition: all var(--transition-speed);
        }

        .select-input:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 10px rgba(109, 74, 255, 0.3);
        }

        /* Action buttons */
        .action-btn {
            background: rgba(109, 74, 255, 0.2);
            border: 1px solid var(--primary-color);
            color: var(--text-primary);
            padding: 0.5rem 1rem;
            border-radius: 6px;
            cursor: pointer;
            font-family: var(--font-mono);
            font-size: 0.85rem;
            transition: all var(--transition-speed);
            white-space: nowrap;
        }

        .action-btn:hover:not(:disabled) {
            background: rgba(109, 74, 255, 0.3);
            box-shadow: 0 0 15px rgba(109, 74, 255, 0.4);
        }

        .action-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: rgba(109, 74, 255, 0.1);
        }

        .action-btn.clear {
            background: rgba(0, 212, 255, 0.2);
            border-color: var(--accent-color);
        }

        .action-btn.clear:hover:not(:disabled) {
            background: rgba(0, 212, 255, 0.3);
            box-shadow: 0 0 15px rgba(0, 212, 255, 0.4);
        }

        .control-count {
            color: var(--text-secondary);
            font-family: var(--font-mono);
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            padding: 0.5rem;
            margin-left: auto;
        }

        /* Log window - fixed height fitting container */
        .log-window {
            flex: 1;
            overflow-y: auto;
            padding: 1rem;
            font-family: var(--font-mono);
            font-size: 0.85rem;
            line-height: 1.6;
            color: #c7c7d4;
            background: transparent;
            scrollbar-width: thin;
            scrollbar-color: var(--primary-color) var(--bg-panel);
            min-height: 0;
        }

        .log-window::-webkit-scrollbar {
            width: 8px;
        }

        .log-window::-webkit-scrollbar-track {
            background: var(--bg-panel);
        }

        .log-window::-webkit-scrollbar-thumb {
            background: var(--primary-color);
            border-radius: 4px;
        }

        /* Log line - SINGLE LINE FORMAT */
        .log-entry {
            padding: 0.4rem 0.6rem;
            border-left: 3px solid transparent;
            transition: all 0.2s;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            cursor: pointer;
        }

        .log-entry:hover {
            background: rgba(109, 74, 255, 0.1);
            overflow: visible;
            z-index: 1;
            position: relative;
        }

        .log-entry.error {
            border-left-color: var(--danger-color);
            color: #ffb3ba;
        }

        .log-entry.warning {
            border-left-color: var(--warning-color);
            color: #ffeebb;
        }

        .log-entry.info {
            border-left-color: var(--accent-color);
        }

        .log-entry.success {
            border-left-color: var(--success-color);
        }

        .timestamp {
            color: var(--text-secondary);
            font-weight: 600;
            flex-shrink: 0;
            min-width: 140px;
        }

        .severity-tag {
            display: inline-block;
            padding: 0.15rem 0.6rem;
            border-radius: 4px;
            font-size: 0.7rem;
            font-weight: 600;
            flex-shrink: 0;
            text-transform: uppercase;
        }

        .tag-error { background: rgba(255, 68, 102, 0.2); color: var(--danger-color); }
        .tag-warning { background: rgba(255, 170, 0, 0.2); color: var(--warning-color); }
        .tag-info { background: rgba(0, 212, 255, 0.2); color: var(--accent-color); }
        .tag-success { background: rgba(0, 255, 136, 0.2); color: var(--success-color); }

        .log-message {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            flex: 1;
        }

        /* Pagination controls */
        .pagination-controls {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 1rem;
            padding: 1rem;
            background: rgba(109, 74, 255, 0.05);
            border-top: 1px solid rgba(109, 74, 255, 0.2);
            flex-shrink: 0;
        }

        .pagination-btn {
            background: rgba(109, 74, 255, 0.2);
            border: 1px solid var(--primary-color);
            color: var(--text-primary);
            padding: 0.5rem 1rem;
            border-radius: 6px;
            cursor: pointer;
            font-family: var(--font-mono);
            font-size: 0.85rem;
            transition: all var(--transition-speed);
        }

        .pagination-btn:hover:not(:disabled) {
            background: rgba(109, 74, 255, 0.3);
            box-shadow: 0 0 15px rgba(109, 74, 255, 0.4);
        }

        .pagination-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: rgba(109, 74, 255, 0.1);
        }

        .pagination-info {
            color: var(--text-secondary);
            font-family: var(--font-mono);
            font-size: 0.85rem;
        }

        /* Footer info */
        .footer-bar {
            margin-top: auto;
            padding: 0.75rem 1.5rem;
            border-top: 1px solid rgba(109, 74, 255, 0.2);
            display: flex;
            justify-content: space-between;
            align-items: center;
            color: var(--text-secondary);
            font-family: var(--font-mono);
            font-size: 0.75rem;
        }

        .lumo-credit {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: var(--primary-color);
        }

        .lumo-logo {
            width: 24px;
            height: 24px;
            position: relative;
        }

        .lumo-logo svg {
            width: 100%;
            height: 100%;
            filter: drop-shadow(0 0 6px rgba(109, 74, 255, 0.6));
        }

        /* Tooltip for truncated messages */
        .log-entry[data-tooltip]:hover::before {
            content: attr(data-tooltip);
            position: absolute;
            top: 100%;
            left: 0;
            background: rgba(10, 10, 15, 0.98);
            border: 1px solid var(--primary-color);
            border-radius: 6px;
            padding: 0.75rem 1rem;
            min-width: 300px;
            max-width: 600px;
            white-space: normal;
            word-break: break-word;
            z-index: 100;
            pointer-events: none;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.8);
        }

        /* Loading state */
        .loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 200px;
            color: var(--accent-color);
        }

        .loading-dots::after {
            content: '';
            animation: dots 1.5s steps(4, end) infinite;
        }

        @keyframes dots {
            0%, 20% { content: ''; }
            40% { content: '.'; }
            60% { content: '..'; }
            80%, 100% { content: '...'; }
        }

        /* Responsive adjustments */
        @media (max-width: 1024px) {
            .control-bar { flex-direction: column; align-items: stretch; }
            .control-group { min-width: 100%; flex: none; }
        }

        @media (max-width: 768px) {
            .hero-content { padding: 1rem; }
            .tech-frame { padding: 2rem 2rem; }
            .logo-text { font-size: 2rem; letter-spacing: 0.15em; }
            .logs-section { padding: 1rem; }
            .log-window { font-size: 0.75rem; padding: 1rem; }
            .header-actions button { padding: 0.4rem 0.8rem; font-size: 0.75rem; }
            .header-title { font-size: 1rem; }
            .timestamp { min-width: 100px; font-size: 0.75rem; }
            .date-input { padding: 0.4rem; font-size: 0.75rem; }
        }
    </style>
</head>
<body>
    <!-- === SECTION 1: HERO === -->
    <section class="section hero-section" id="home">
        <div class="hero-bg"></div>
        <div class="particles" id="particles"></div>
        <div class="scan-line"></div>

        <div class="hero-content">
            <div class="tech-frame">
                <h1 class="logo-text">LAB ANALYZER</h1>
            </div>
            <p class="subtext">/// SYSTEM MONITORING & LOG ANALYSIS ///</p>
        </div>

        <div class="scroll-indicator" onclick="scrollToSection()">
            <div class="scroll-arrow"></div>
        </div>
    </section>

    <!-- === SECTION 2: LOGS DISPLAY === -->
    <section class="section logs-section" id="logs">
        <div class="logs-header">
            <div class="header-title">
                <span class="status-indicator"></span>
                <span>LIVE LOG STREAM</span>
            </div>
            <div class="header-actions">
                <button id="btnRefresh" onclick="refreshLogs()">Refresh</button>
                <button id="btnExport" onclick="exportLogs()">Export</button>
                <button id="btnAutoScroll" onclick="toggleAutoScroll()">Auto-scroll: ON</button>
            </div>
        </div>

        <?php if ($errorMsg): ?>
        <div class="error-message visible">
            ⚠ <?php echo htmlspecialchars($errorMsg); ?>
        </div>
        <?php endif; ?>

        <div class="log-container">
            <!-- Control Bar with Filters, Sort, and Date Range -->
            <div class="control-bar">
                <div class="control-group">
                    <input type="text"
                           class="filter-input"
                           id="filterInput"
                           placeholder="Filter logs..."
                           value="<?php echo htmlspecialchars($filterPattern); ?>">
                    <button class="action-btn" onclick="applyFilter()">Apply</button>
                    <button class="action-btn clear" onclick="clearFilter()">Clear</button>
                </div>

                <div class="control-group">
                    <select class="select-input" id="sortSelect" onchange="applySort()">
                        <option value="desc" <?php echo $sortOrder === 'desc' ? 'selected' : ''; ?>>Recent First</option>
                        <option value="asc" <?php echo $sortOrder === 'asc' ? 'selected' : ''; ?>>Oldest First</option>
                        <option value="range" <?php echo $sortOrder === 'range' ? 'selected' : ''; ?>>Date Range...</option>
                    </select>
                </div>

                <div class="control-group date-range-group" id="dateRangeGroup" style="display: <?php echo $sortOrder === 'range' ? 'flex' : 'none'; ?>;">
                    <input type="date" class="date-input" id="dateFrom" value="<?php echo htmlspecialchars($dateFrom); ?>">
                    <span style="color: var(--text-secondary);">to</span>
                    <input type="date" class="date-input" id="dateTo" value="<?php echo htmlspecialchars($dateTo); ?>">
                    <button class="action-btn" onclick="applyDateRange()">Apply</button>
                </div>

                <span class="control-count">Showing: <span id="visibleCount"><?php echo count($paginatedLines); ?></span>/<span id="totalCount"><?php echo $lineCount; ?></span></span>
            </div>

            <div class="log-window" id="logWindow">
                <?php if (!empty($logContent)): ?>
                    <?php foreach ($paginatedLines as $line): ?>
                        <?php if (trim($line) === '') continue; ?>

                        <?php
                        // Analyze log line for severity
                        $lineLower = strtolower($line);
                        $severity = 'info';
                        $tagClass = 'tag-info';

                        if (strpos($lineLower, 'error') !== false || strpos($lineLower, 'failed') !== false || strpos($lineLower, 'fail') !== false) {
                            $severity = 'error';
                            $tagClass = 'tag-error';
                        } elseif (strpos($lineLower, 'warning') !== false || strpos($lineLower, 'warn') !== false) {
                            $severity = 'warning';
                            $tagClass = 'tag-warning';
                        } elseif (strpos($lineLower, 'success') !== false || strpos($lineLower, 'completed') !== false) {
                            $severity = 'success';
                            $tagClass = 'tag-success';
                        }

                        $fullMessage = htmlspecialchars($line);
                        $timestampDisplay = htmlspecialchars(substr($line, 0, 25));
                        $messageDisplay = htmlspecialchars(substr($line, 25));
                    ?>
                    <div class="log-entry <?php echo $severity; ?>"
                         data-severity="<?php echo $severity; ?>"
                         data-tooltip="<?php echo $fullMessage; ?>">
                        <span class="timestamp"><?php echo $timestampDisplay; ?></span>
                        <span class="severity-tag <?php echo $tagClass; ?>"><?php echo strtoupper($severity); ?></span>
                        <span class="log-message"><?php echo $messageDisplay; ?></span>
                    </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <div class="loading"><span class="loading-dots">Loading logs</span></div>
                <?php endif; ?>
            </div>

            <!-- Pagination Controls -->
            <?php if (!empty($logContent) && $totalPages > 1): ?>
            <div class="pagination-controls">
                <button class="pagination-btn" id="btnPrev" onclick="changePage(-1)" <?php echo $currentPage <= 1 ? 'disabled' : ''; ?>>
                    ← Previous
                </button>
                <span class="pagination-info">Page <span id="currentPageNum"><?php echo $currentPage; ?></span> of <span id="totalPages"><?php echo $totalPages; ?></span> (<?php echo count($paginatedLines); ?> entries)</span>
                <button class="pagination-btn" id="btnNext" onclick="changePage(1)" <?php echo $currentPage >= $totalPages ? 'disabled' : ''; ?>>
                    Next →
                </button>
            </div>
            <?php endif; ?>
        </div>

        <div class="footer-bar">
            <span id="lineCount">Total Lines: <?php echo $lineCount; ?></span>
            <span>Path: <?php echo htmlspecialchars($logPath); ?></span>
            <span>PHP <?php echo phpversion(); ?></span>
            <div class="lumo-credit">
                <div class="lumo-logo">
                    <!-- Lumo Cat Logo SVG -->
                    <svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
                        <!-- Body -->
                        <ellipse cx="32" cy="38" rx="14" ry="10" fill="#6d4aff"/>
                        <!-- Head -->
                        <circle cx="32" cy="22" r="10" fill="#6d4aff"/>
                        <!-- Ears -->
                        <polygon points="24,14 20,6 28,12" fill="#6d4aff"/>
                        <polygon points="40,14 44,6 36,12" fill="#6d4aff"/>
                        <!-- Eyes (white ovals) -->
                        <ellipse cx="28" cy="21" rx="3" ry="2.5" fill="#ffffff"/>
                        <ellipse cx="36" cy="21" rx="3" ry="2.5" fill="#ffffff"/>
                        <!-- Pupils (small dark ovals) -->
                        <ellipse cx="28" cy="21.5" rx="0.8" ry="1" fill="#1a1a2e"/>
                        <ellipse cx="36" cy="21.5" rx="0.8" ry="1" fill="#1a1a2e"/>
                        <!-- Mouth -->
                        <path d="M 30 26 Q 32 27 34 26" stroke="#1a1a2e" stroke-width="1" fill="none"/>
                        <!-- Medallion -->
                        <circle cx="32" cy="50" r="3" fill="#ffd700"/>
                        <!-- Cord -->
                        <line x1="25" y1="35" x2="32" y2="47" stroke="#1a1a2e" stroke-width="1"/>
                        <line x1="39" y1="35" x2="32" y2="47" stroke="#1a1a2e" stroke-width="1"/>
                    </svg>
                </div>
                <span>Code created by Lumo</span>
            </div>
        </div>
    </section>

    <!-- === JAVASCRIPT === -->
    <script>
        // === STATE MANAGEMENT ===
        let autoScrollEnabled = true;
        let lastLineCount = <?php echo $lineCount; ?>;
        let isPolling = true;
        let pollIntervalId = null;
        let currentPage = <?php echo $currentPage ?? 1; ?>;
        let totalPages = <?php echo $totalPages ?? 1; ?>;
        let currentFilter = '<?php echo htmlspecialchars($filterPattern); ?>';
        let currentSort = '<?php echo $sortOrder; ?>';
        const logWindow = document.getElementById('logWindow');

        // === SCROLL TO SECTION 2 FUNCTION ===
        function scrollToSection() {
            document.getElementById('logs').scrollIntoView({ behavior: 'smooth' });
        }

        // === PARTICLES ===
        function createParticles(count = 30) {
            const container = document.getElementById('particles');
            for (let i = 0; i < count; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.left = Math.random() * 100 + '%';
                particle.style.animationDelay = Math.random() * 15 + 's';
                particle.style.animationDuration = (Math.random() * 10 + 10) + 's';
                container.appendChild(particle);
            }
        }

        // === FILTER FUNCTIONS ===
        function applyFilter() {
            const filterValue = document.getElementById('filterInput').value.trim();
            currentFilter = filterValue;
            scrollToSection();

            const url = new URL(window.location.href);
            if (filterValue) {
                url.searchParams.set('filter', filterValue);
            } else {
                url.searchParams.delete('filter');
            }
            url.searchParams.delete('page');

            window.location.href = url.toString();
        }

        function clearFilter() {
            document.getElementById('filterInput').value = '';
            currentFilter = '';
            scrollToSection();

            const url = new URL(window.location.href);
            url.searchParams.delete('filter');
            url.searchParams.delete('page');

            window.location.href = url.toString();
        }

        // === SORT FUNCTIONS ===
        function applySort() {
            const sortValue = document.getElementById('sortSelect').value;
            currentSort = sortValue;
            scrollToSection();

            const dateRangeGroup = document.getElementById('dateRangeGroup');
            dateRangeGroup.style.display = sortValue === 'range' ? 'flex' : 'none';

            const url = new URL(window.location.href);
            if (sortValue === 'range') {
                url.searchParams.set('sort', 'range');
            } else {
                url.searchParams.set('sort', sortValue);
            }
            url.searchParams.delete('page');

            window.location.href = url.toString();
        }

        function applyDateRange() {
            const dateFrom = document.getElementById('dateFrom').value;
            const dateTo = document.getElementById('dateTo').value;
            scrollToSection();

            const url = new URL(window.location.href);
            url.searchParams.set('sort', 'range');

            if (dateFrom) {
                url.searchParams.set('date_from', dateFrom);
            } else {
                url.searchParams.delete('date_from');
            }

            if (dateTo) {
                url.searchParams.set('date_to', dateTo);
            } else {
                url.searchParams.delete('date_to');
            }

            url.searchParams.delete('page');
            window.location.href = url.toString();
        }

        // === PAGINATION FUNCTIONS ===
        function changePage(delta) {
            scrollToSection();

            const url = new URL(window.location.href);
            const newPage = currentPage + delta;

            if (newPage >= 1 && newPage <= totalPages) {
                url.searchParams.set('page', newPage);

                if (currentFilter) {
                    url.searchParams.set('filter', currentFilter);
                }
                if (currentSort) {
                    url.searchParams.set('sort', currentSort);
                }
                if (currentSort === 'range') {
                    const dateFrom = document.getElementById('dateFrom').value;
                    const dateTo = document.getElementById('dateTo').value;
                    if (dateFrom) url.searchParams.set('date_from', dateFrom);
                    if (dateTo) url.searchParams.set('date_to', dateTo);
                }

                window.location.href = url.toString();
            }
        }

        // === TOGGLE AUTO-SCROLL ===
        function toggleAutoScroll() {
            autoScrollEnabled = !autoScrollEnabled;
            const btn = document.getElementById('btnAutoScroll');
            btn.textContent = autoScrollEnabled ? 'Auto-scroll: ON' : 'Auto-scroll: OFF';

            if (autoScrollEnabled && logWindow.scrollTop < logWindow.scrollHeight - logWindow.clientHeight - 100) {
                logWindow.scrollTo({ top: logWindow.scrollHeight, behavior: 'smooth' });
            }
        }

        // === REFRESH LOGS VIA AJAX ===
        async function refreshLogs() {
            scrollToSection();

            const btn = document.getElementById('btnRefresh');
            const originalText = btn.textContent;
            btn.textContent = 'Loading...';
            btn.disabled = true;

            try {
                const response = await fetch(window.location.pathname + '?refresh=1');

                if (response.ok) {
                    const html = await response.text();
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const newLogs = doc.querySelector('#logWindow').innerHTML;
                    const lineCountEl = doc.querySelector('#lineCount');

                    logWindow.innerHTML = newLogs;

                    if (lineCountEl) {
                        document.getElementById('lineCount').textContent = lineCountEl.textContent;
                    }

                    if (autoScrollEnabled) {
                        setTimeout(() => {
                            logWindow.scrollTo({ top: logWindow.scrollHeight, behavior: 'smooth' });
                        }, 100);
                    }
                } else {
                    throw new Error('HTTP ' + response.status);
                }
            } catch (error) {
                logWindow.innerHTML = '<div class="error-message visible">Failed to refresh: ' + error.message + '</div>';
                console.error('Refresh error:', error);
            } finally {
                btn.textContent = originalText;
                btn.disabled = false;
            }
        }

        // === EXPORT LOGS ===
        async function exportLogs() {
            scrollToSection();

            const btn = document.getElementById('btnExport');
            const originalText = btn.textContent;
            btn.textContent = 'Preparing...';
            btn.disabled = true;

            try {
                const response = await fetch('?export=1');

                if (!response.ok) {
                    throw new Error('Download failed: ' + response.statusText);
                }

                const blob = await response.blob();
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'labs_export_' + new Date().toISOString().slice(0, 10) + '.log';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            } catch (error) {
                alert('Export failed: ' + error.message);
                console.error('Export error:', error);
            } finally {
                btn.textContent = originalText;
                btn.disabled = false;
            }
        }

        // === AUTO-POLL FOR NEW LOG ENTRIES ===
        function startPolling() {
            if (pollIntervalId) clearInterval(pollIntervalId);

            pollIntervalId = setInterval(async () => {
                if (!isPolling) return;

                const atBottom = logWindow.scrollTop >= logWindow.scrollHeight - logWindow.clientHeight - 100;

                if (atBottom || autoScrollEnabled) {
                    try {
                        const response = await fetch('?poll=1');
                        const newCount = parseInt(response.headers.get('X-Log-Line-Count') || lastLineCount);

                        if (newCount !== lastLineCount) {
                            const html = await response.text();
                            if (html.trim() !== '' && html !== logWindow.innerHTML.replace(/^\s+|\s+$/g, '')) {
                                logWindow.innerHTML = html;
                                document.getElementById('lineCount').textContent = 'Total Lines: ' + newCount;
                                lastLineCount = newCount;

                                if (autoScrollEnabled) {
                                    logWindow.scrollTo({ top: logWindow.scrollHeight, behavior: 'smooth' });
                                }
                            }
                        }
                    } catch (error) {
                        console.debug('Polling error:', error.message);
                    }
                }
            }, 3000);
        }

        // === INITIALIZE ===
        document.addEventListener('DOMContentLoaded', () => {
            createParticles();

            document.getElementById('btnAutoScroll').textContent = autoScrollEnabled ? 'Auto-scroll: ON' : 'Auto-scroll: OFF';

            if (autoScrollEnabled && logWindow) {
                setTimeout(() => {
                    logWindow.scrollTo({ top: logWindow.scrollHeight, behavior: 'smooth' });
                }, 300);
            }

            document.getElementById('lineCount').textContent = 'Total Lines: ' + <?php echo $lineCount; ?>;

            const scrollIndicator = document.querySelector('.scroll-indicator');
            scrollIndicator.addEventListener('click', () => {
                scrollToSection();
            });

            document.getElementById('filterInput').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    applyFilter();
                }
            });

            startPolling();
        });

        // === PAUSE POLLING WHEN USER SCROLLS UP ===
        if (logWindow) {
            logWindow.addEventListener('scroll', () => {
                const atBottom = logWindow.scrollTop >= logWindow.scrollHeight - logWindow.clientHeight - 100;
                if (!atBottom && autoScrollEnabled) {
                    isPolling = false;
                } else if (atBottom && !isPolling) {
                    isPolling = true;
                }
            });
        }
    </script>
</body>
</html>
