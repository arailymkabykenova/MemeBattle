# 🎮 WebSocket Multi-User Testing Instructions

## 📋 Setup for Multi-User Testing

### Step 1: Open Two Browser Windows

1. **Window 1 (WebSocketTester):** 
   - Open `websocket_test_client.html`
   - User ID: 11
   - Will automatically connect

2. **Window 2 (Player2WS):**
   - Open `websocket_test_client_player2.html` 
   - User ID: 12
   - Will automatically connect

### Step 2: Create and Join Room 11

**In Window 1 (WebSocketTester):**
1. First create a room via API: `POST http://localhost:8000/rooms/`
2. Or use existing room ID 11

**In Window 2 (Player2WS):**
1. Click "🚪 Join Room 11" button
2. Should see success message

**In Window 1 (WebSocketTester):**
1. Should receive notification that Player2WS joined the room

### Step 3: Test Real-Time Communication

Try these actions and watch notifications in both windows:

- **Ping/Pong:** Click ping in any window, see response
- **Room state updates:** When someone joins/leaves
- **Game start:** When room creator starts a game

## 🛠️ Fixed Issues

1. ✅ **RoomDetailResponse serialization error** - Fixed by using `.model_dump()`
2. ✅ **WebSocket state synchronization** - Removed auto-room-join on connect
3. ✅ **Database vs WebSocket state mismatch** - Fixed join_room logic
4. ✅ **Error handling** - Added proper try/catch blocks

## 📊 Expected Flow

1. **Connection:** Both users auto-connect on page load
2. **Room Creation:** User 11 creates room (via API)
3. **Room Joining:** User 12 joins room 11 via WebSocket
4. **Real-time Updates:** Both users see live notifications
5. **Game Flow:** Can start games, submit choices, vote, etc.

## 🔧 Troubleshooting

- **Connection Issues:** Check server is running on port 8000
- **Token Expired:** Use fresh JWT tokens
- **State Mismatch:** Restart server to clear state
- **JSON Errors:** Ensure proper data format in custom messages

## 🎯 Test Scenarios

### Basic Room Operations
- [x] Join room
- [x] Leave room
- [x] Room state updates
- [x] Creator leaves (room cancellation)

### Game Operations (when game service is ready)
- [ ] Start game
- [ ] Submit card choices
- [ ] Vote on cards
- [ ] Round results
- [ ] Game completion

### Connection Management
- [x] Auto-reconnect
- [x] Handle disconnections
- [x] Ping/pong keepalive
- [x] Multiple connections per user

Now you can test real-time multi-user interactions! 🎉 