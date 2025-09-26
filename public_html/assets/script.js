// Configuration and Constants
const CONFIG = {
  // WebSocket Configuration
  wsUrl: window.location.protocol === 'file:' 
    ? 'ws://localhost:2069'  // Fallback for local file testing
    : `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/ws`, // Secure WebSocket for HTTPS

  // Font Configuration
  baseFontSize: 12,
  defaultRainFontSize: 10, // 2 points smaller than base
  messageFontSize: 16,     // Used for column calculations

  // Font sizes for different log levels (progressive sizing)
  fontSizes: {
    debug: 12,      // Base size
    info: 14,       // Base + 2
    notice: 16,     // Base + 4
    warning: 18,    // Base + 6
    error: 20,      // Base + 8
    critical: 22,   // Base + 10
    alert: 24,      // Base + 12
    emergency: 26   // Base + 14
  },

  // Colors for different log levels
  colors: {
    emergency: '#FF0000',  // Red
    alert: '#FF0000',      // Red
    critical: '#FF0000',   // Red
    error: '#FF0000',      // Red
    warning: '#FFA500',    // Orange
    notice: '#FFFF00',     // Yellow
    info: '#FFFF00',       // Yellow
    debug: '#00FF00',      // Green
    background: '#004400'   // Dark green for background rain
  },

  // Performance settings
  maxQueueSize: 500,
  speedUpdateInterval: 1000, // Update speed every second
  defaultDrawInterval: 30,   // Default 30ms (about 33 FPS)
  minDrawInterval: 10,       // Fastest frame rate (100 FPS)
  queueThresholds: {
    slow: 100,   // Use slow frame rate below this queue size
    fast: 400    // Use fast frame rate above this queue size
  }
};

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  // Initialize WebSocket
  const ws = new WebSocket(CONFIG.wsUrl);
  const statusIndicator = document.getElementById('connection-status');
  const indicatorPanel = document.getElementById('indicator-panel');

  // Feature flags
  const urlParams = new URLSearchParams(window.location.search);
  const blueSecondDrop = urlParams.get('blue') === 'true';

  // UI Event Handlers
  statusIndicator.addEventListener('click', () => {
    const isMinimized = indicatorPanel.classList.contains('minimized');
    indicatorPanel.classList.toggle('minimized', !isMinimized);
  });

  // Set initial connection status
  statusIndicator.className = 'connecting';

  // State Management
  const STATE = {
    // Canvas setup
    canvas: document.getElementById('matrix'),
    ctx: null,
    columns: 0,
    maxFontSize: 0,

    // Message tracking
    messageTimestamps: [],
    dropCreationTimestamps: [],
    totalMessagesReceived: 0,
    totalDropsCreated: 0,
    totalLostMessages: 0,
    lastSpeedUpdate: Date.now(),
    lastQueueSize: 0,

    // Performance tracking
    currentDrawInterval: CONFIG.defaultDrawInterval,
    drawIntervalId: null,

    // Rain effect
    drops: [],
    multiDropColumns: [],
    messageQueue: [],

    // Characters for rain effect
    alphabet: (() => {
      const katakana = 'アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン';
      const latin = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const nums = '0123456789';
      return katakana + latin + nums;
    })()
  };

  // Initialize canvas
  STATE.ctx = STATE.canvas.getContext('2d');
  STATE.canvas.width = window.innerWidth;
  STATE.canvas.height = window.innerHeight;

  // Calculate columns based on largest possible font size
  STATE.maxFontSize = Math.max(...Object.values(CONFIG.fontSizes));
  STATE.columns = Math.floor(STATE.canvas.width / STATE.maxFontSize);
  STATE.drops = Array(STATE.columns).fill().map(() => []);

  // WebSocket Event Handlers
  ws.onopen = () => {
    statusIndicator.className = 'connected';
  };

  ws.onclose = () => {
    statusIndicator.className = 'disconnected';
    setTimeout(() => window.location.reload(), 3000);
  };

  ws.onerror = () => {
    statusIndicator.className = 'disconnected';
  };

  ws.onmessage = (event) => {
    const logEntry = JSON.parse(event.data);
    STATE.totalMessagesReceived++;
    STATE.messageTimestamps.push(Date.now());
    createNewRainDrop(logEntry);
  };

  // DOM Elements for stats display
  const UI = {
    speedIndicator: document.getElementById('speed-indicator'),
    queueIndicator: document.getElementById('queue-indicator'),
    dropSpeedIndicator: document.getElementById('drop-speed-indicator'),
    receivedIndicator: document.getElementById('received-indicator'),
    dropsIndicator: document.getElementById('drops-indicator'),
    lostIndicator: document.getElementById('lost-indicator'),
    intervalIndicator: document.getElementById('interval-indicator')
  };

  /**
   * Utility Functions
   */

  // Generate random characters for rain effect
  function getRandomChars(length = 3) {
    return Array(length).fill()
      .map(() => STATE.alphabet[Math.floor(Math.random() * STATE.alphabet.length)])
      .join('');
  }

  // Calculate dynamic frame interval based on queue size
  function calculateDrawInterval(queueSize) {
    const { slow, fast } = CONFIG.queueThresholds;
    if (queueSize < slow) return CONFIG.defaultDrawInterval;
    if (queueSize > fast) return CONFIG.minDrawInterval;
    
    const progress = (queueSize - slow) / (fast - slow);
    return Math.round(CONFIG.defaultDrawInterval - (progress * (CONFIG.defaultDrawInterval - CONFIG.minDrawInterval)));
  }

  // Update the draw interval if queue size has changed significantly
  function updateDrawInterval() {
    const newInterval = calculateDrawInterval(STATE.messageQueue.length);
    if (newInterval !== STATE.currentDrawInterval) {
      STATE.currentDrawInterval = newInterval;
      if (STATE.drawIntervalId) clearInterval(STATE.drawIntervalId);
      STATE.drawIntervalId = setInterval(draw, STATE.currentDrawInterval);
    }
  }

  /**
   * Rain Effect Functions
   */

  // Create a new rain drop from a log entry
  function createNewRainDrop(logEntry) {
    STATE.messageQueue.push({
      message: logEntry.message,
      color: CONFIG.colors[logEntry.level],
      level: logEntry.level,
      fontSize: CONFIG.fontSizes[logEntry.level] || CONFIG.baseFontSize
    });

    if (STATE.messageQueue.length >= CONFIG.maxQueueSize) {
      handleQueueOverflow();
    }
  }

  // Handle queue overflow by creating a visual effect and clearing the queue
  function handleQueueOverflow() {
    STATE.totalLostMessages += STATE.messageQueue.length;
    const predominantLevel = getPredominantLevel(analyzeQueueLevels());
    STATE.messageQueue.length = 0;

    UI.queueIndicator.textContent = 'Cleared';
    UI.queueIndicator.style.color = '#ff0000';

    setTimeout(() => {
      STATE.lastQueueSize = 0;
      updateSpeedIndicator();
    }, 1500);

    createSimultaneousDrops(predominantLevel);
  }

  // Analyze queue to determine predominant log level
  function analyzeQueueLevels() {
    const levelCounts = Object.keys(CONFIG.colors)
      .reduce((acc, level) => ({ ...acc, [level]: 0 }), {});

    STATE.messageQueue.forEach(message => {
      if (levelCounts.hasOwnProperty(message.level)) {
        levelCounts[message.level]++;
      }
    });

    return levelCounts;
  }

  // Get the predominant log level from counts
  function getPredominantLevel(levelCounts) {
    return Object.entries(levelCounts)
      .reduce((prev, [level, count]) => 
        count > prev.count ? { level, count } : prev,
        { level: 'info', count: 0 }
      ).level;
  }

  // Create Matrix-style simultaneous drops effect
  function createSimultaneousDrops(level = 'info') {
    const color = CONFIG.colors[level] || CONFIG.colors.debug;
    
    STATE.drops = STATE.drops.map(() => [{
      y: 1,
      message: getRandomChars(5 + Math.floor(Math.random() * 4)),
      color,
      isMessage: true,
      level,
      fontSize: CONFIG.fontSizes[level] || CONFIG.baseFontSize,
      messageIndex: 0
    }]);
  }

  /**
   * Animation and Update Functions
   */

  // Update speed and stats indicators
  function updateSpeedIndicator() {
    const now = Date.now();
    const tenSecondsAgo = now - 10000;

    // Prune old timestamps
    STATE.messageTimestamps = STATE.messageTimestamps.filter(t => t >= tenSecondsAgo);
    STATE.dropCreationTimestamps = STATE.dropCreationTimestamps.filter(t => t >= tenSecondsAgo);

    if (now - STATE.lastSpeedUpdate >= CONFIG.speedUpdateInterval) {
      updateStats(now);
      STATE.lastSpeedUpdate = now;
    }
  }

  // Update all UI statistics
  function updateStats(now) {
    const messagesPerSecond = STATE.messageTimestamps.length / 10;
    const dropsPerSecond = STATE.dropCreationTimestamps.length / 10;
    const currentQueueSize = STATE.messageQueue.length;

    // Update all indicators
    UI.speedIndicator.textContent = `${Math.round(messagesPerSecond * 10) / 10} msgs/s`;
    UI.dropSpeedIndicator.textContent = `${Math.round(dropsPerSecond * 10) / 10} drops/s`;
    UI.receivedIndicator.textContent = `${STATE.totalMessagesReceived.toLocaleString()} received`;
    UI.dropsIndicator.textContent = `${STATE.totalDropsCreated.toLocaleString()} drops`;
    UI.lostIndicator.textContent = `${STATE.totalLostMessages.toLocaleString()} lost`;
    
    // Update colors based on state
    UI.lostIndicator.style.color = STATE.totalLostMessages > 0 ? '#ff0000' : '';
    updateQueueIndicator(currentQueueSize);
    
    // Update performance indicators
    updateDrawInterval();
    UI.intervalIndicator.textContent = `${Math.round(1000 / STATE.currentDrawInterval)} FPS (${STATE.currentDrawInterval}ms)`;
  }

  // Update queue indicator with appropriate color
  function updateQueueIndicator(currentQueueSize) {
    UI.queueIndicator.textContent = `${currentQueueSize} queued`;
    
    if (currentQueueSize === 0) {
      UI.queueIndicator.style.color = '#00ff00';
    } else if (currentQueueSize > STATE.lastQueueSize) {
      UI.queueIndicator.style.color = '#ff0000';
    } else if (currentQueueSize < STATE.lastQueueSize) {
      UI.queueIndicator.style.color = '#ffff00';
    } else {
      UI.queueIndicator.style.color = '';
    }
    
    STATE.lastQueueSize = currentQueueSize;
  }

  // Process message queue and create new drops
  function processMessageQueue() {
    const mps = STATE.messageTimestamps.filter(t => t >= Date.now() - 10000).length / 10;
    const numMultiDropColumns = Math.max(0, Math.floor((mps - 20) / 2));

    // Update multi-drop columns
    updateMultiDropColumns(numMultiDropColumns);
    
    // Place messages from queue
    while (STATE.messageQueue.length > 0) {
      if (!tryPlaceNextMessage()) break;
    }
  }

  // Update which columns can have multiple drops
  function updateMultiDropColumns(count) {
    const availableColumns = Array.from({ length: STATE.columns }, (_, i) => i);
    STATE.multiDropColumns = [];
    
    for (let i = 0; i < count && availableColumns.length > 0; i++) {
      const randomIndex = Math.floor(Math.random() * availableColumns.length);
      STATE.multiDropColumns.push(availableColumns.splice(randomIndex, 1)[0]);
    }
  }

  // Try to place the next message from the queue
  function tryPlaceNextMessage() {
    // Try multi-drop columns first
    for (const colIndex of STATE.multiDropColumns) {
      if (canAddSecondDrop(STATE.drops[colIndex])) {
        addDropToColumn(colIndex, true);
        return true;
      }
    }

    // Then try empty columns
    const emptyColumns = STATE.drops
      .map((drops, index) => ({ drops, index }))
      .filter(({ drops }) => drops.length === 0)
      .map(({ index }) => index);

    if (emptyColumns.length > 0) {
      const randomIndex = emptyColumns[Math.floor(Math.random() * emptyColumns.length)];
      addDropToColumn(randomIndex, false);
      return true;
    }

    return false;
  }

  // Check if a column can accept a second drop
  function canAddSecondDrop(columnDrops) {
    return columnDrops.length === 1 && 
           columnDrops[0].y * columnDrops[0].fontSize > STATE.canvas.height / 3;
  }

  // Add a new drop to a specific column
  function addDropToColumn(columnIndex, isSecondDrop) {
    const nextMessage = STATE.messageQueue.shift();
    STATE.dropCreationTimestamps.push(Date.now());
    STATE.totalDropsCreated++;
    
    STATE.drops[columnIndex].push({
      y: 0,
      message: nextMessage.message,
      color: isSecondDrop && blueSecondDrop ? '#0000FF' : nextMessage.color,
      level: nextMessage.level,
      fontSize: nextMessage.fontSize,
      isMessage: true,
      messageIndex: 0
    });
  }

  // Add background rain effect
  function addBackgroundRain() {
    STATE.drops.forEach((columnDrops, i) => {
      if (columnDrops.length === 0 && Math.random() > 0.975) {
        columnDrops.push({
          y: 0,
          char: STATE.alphabet[Math.floor(Math.random() * STATE.alphabet.length)],
          color: CONFIG.colors.background,
          isMessage: false,
          level: 'debug',
          fontSize: CONFIG.defaultRainFontSize
        });
      }
    });
  }

  // Main draw function
  function draw() {
    updateSpeedIndicator();
    
    // Fade effect
    STATE.ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
    STATE.ctx.fillRect(0, 0, STATE.canvas.width, STATE.canvas.height);

    processMessageQueue();
    
    // Update and draw drops
    STATE.drops.forEach((columnDrops, i) => {
      for (let j = columnDrops.length - 1; j >= 0; j--) {
        const drop = columnDrops[j];
        drawDrop(drop, i);
        
        drop.y += drop.isMessage ? 0.9 : 1;
        
        if (drop.y * (drop.isMessage ? drop.fontSize : CONFIG.defaultRainFontSize) > STATE.canvas.height) {
          columnDrops.splice(j, 1);
        }
      }
    });

    addBackgroundRain();
  }

  // Draw a single drop
  function drawDrop(drop, columnIndex) {
    const fontSize = drop.isMessage ? drop.fontSize : CONFIG.defaultRainFontSize;
    STATE.ctx.font = `${fontSize}px monospace`;
    STATE.ctx.fillStyle = drop.color;
    
    if (drop.isMessage) {
      const currentChar = drop.message[drop.messageIndex];
      STATE.ctx.fillText(currentChar, columnIndex * STATE.maxFontSize, drop.y * fontSize);
      drop.messageIndex = (drop.messageIndex + 1) % drop.message.length;
    } else {
      const randomChar = STATE.alphabet[Math.floor(Math.random() * STATE.alphabet.length)];
      STATE.ctx.fillText(randomChar, columnIndex * STATE.maxFontSize, drop.y * fontSize);
    }
  }

  // Handle window resize
  window.addEventListener('resize', () => {
    STATE.canvas.width = window.innerWidth;
    STATE.canvas.height = window.innerHeight;
    
    const newColumns = Math.floor(STATE.canvas.width / STATE.maxFontSize);
    if (newColumns > STATE.columns) {
      STATE.drops.push(...Array(newColumns - STATE.columns).fill().map(() => []));
    } else if (newColumns < STATE.columns) {
      STATE.drops.length = newColumns;
    }
    STATE.columns = newColumns;
  });

  // Start animation
  STATE.drawIntervalId = setInterval(draw, STATE.currentDrawInterval);
});