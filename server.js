#!/usr/bin/env node

/**
 * Real-time Log Visualization Server
 * Receives log entries via HTTP POST and broadcasts them to connected WebSocket clients
 */

// Dependencies
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const bodyParser = require('body-parser');

// Constants
const PORT = process.env.PORT || 2069;
const VALID_LOG_LEVELS = [
    'emergency',
    'alert',
    'critical',
    'error',
    'warning',
    'notice',
    'info',
    'debug'
];

// Server setup
const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(bodyParser.json());
app.use(express.static(__dirname));

// State management
const clients = new Set();
let requestCount = 0;
let lastRequestCount = 0;
let messageCount = 0;
let lastMessageCount = 0;

/**
 * Displays real-time server statistics in the terminal
 * Shows requests per second, messages per second, and total counts
 */
function displayStats() {
    const requestsPerSecond = requestCount - lastRequestCount;
    const messagesPerSecond = messageCount - lastMessageCount;

    process.stdout.write('\r\x1b[K'); // Clear line
    process.stdout.write(
        `Requests/sec: ${requestsPerSecond} | ` +
        `Messages/sec: ${messagesPerSecond} | ` +
        `Total Requests: ${requestCount} | ` +
        `Total Messages: ${messageCount}`
    );

    lastRequestCount = requestCount;
    lastMessageCount = messageCount;
}

/**
 * Broadcasts a message to all connected WebSocket clients
 * @param {Object} message - The message to broadcast
 */
function broadcast(message) {
    clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(message));
        }
    });
    messageCount++;
}

// WebSocket connection handling
wss.on('connection', (ws) => {
    clients.add(ws);
    ws.on('close', () => clients.delete(ws));
});

// REST API endpoints
app.post('/logs', (req, res) => {
    requestCount++;
    const logEntry = req.body;

    // Validate required fields
    if (!logEntry.message || !logEntry.level) {
        return res.status(400).json({ 
            error: 'Missing required fields: message and level' 
        });
    }

    // Normalize and validate log level
    logEntry.level = logEntry.level.toLowerCase();
    if (!VALID_LOG_LEVELS.includes(logEntry.level)) {
        return res.status(400).json({ 
            error: `Invalid log level. Must be one of: ${VALID_LOG_LEVELS.join(', ')}` 
        });
    }

    broadcast(logEntry);
    res.json({ status: 'success' });
});

// Start server
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(''); // Empty lines for stats display
    console.log('');
    
    setInterval(displayStats, 1000);
    displayStats();
});
