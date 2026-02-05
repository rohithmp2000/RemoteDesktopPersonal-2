# Remotely Project - Complete Architecture Analysis

## Project Overview

**Remotely** is a comprehensive remote desktop control and scripting solution built with:

- **Backend**: ASP.NET Core with Blazor Server Components
- **Real-time Communication**: SignalR Core with WebSocket support
- **Desktop Clients**: Avalonia (cross-platform) and platform-specific implementations
- **Agent**: Service-based remote execution agent
- **Database**: Supports SQLite, SQL Server, and PostgreSQL

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          WEB BROWSERS                            │
│                    (Viewer/Control Interface)                    │
└─────────────────────┬───────────────────────────────────────────┘
                      │ HTTPS + WebSocket
                      │
    ┌─────────────────▼───────────────────┐
    │      SERVER (ASP.NET Core)          │
    │  ├─ SignalR Hubs (3 types)          │
    │  ├─ Identity & Authorization        │
    │  ├─ Database (SQLite/MSSQL/PG)      │
    │  ├─ Session Management              │
    │  └─ Blazor UI Components            │
    └─────────────────┬───────────────────┘
          │           │           │
    ┌─────┴─┐   ┌─────┴─┐   ┌────┴──┐
    │ViewerH│   │AgentH │   │DesktopH
    │Hub    │   │Hub    │   │Hub
    └─────┬─┘   └─────┬─┘   └────┬──┘
          │           │           │
     ┌────▼────┐ ┌────▼────┐ ┌───▼────┐
     │  AGENT  │ │ DESKTOP │ │DESKTOP │
     │ Service │ │CLIENTS  │ │CLIENTS │
     │(Windows)│ │(Windows)│ │(Linux) │
     └─────────┘ └─────────┘ └────────┘
```

---

## Core Components

### 1. **Server Project** (ASP.NET Core)

**Location**: `Server/`

**Purpose**: Central hub for all connections, authentication, session management, and web UI.

**Key Features**:

- **SignalR Hubs**: 3 specialized hubs for different client types
  - `AgentHub` - Communicates with remote agents
  - `DesktopHub` - Communicates with desktop clients (casters)
  - `ViewerHub` - Communicates with web browsers (viewers)
- **Database Support**:
  - SQLite (default, lightweight)
  - SQL Server (enterprise)
  - PostgreSQL (enterprise)
- **Authentication**: ASP.NET Core Identity with role-based access
- **Session Management**: Remote control session caching
- **Stream Processing**: Desktop stream caching and recording
- **API Controllers**: REST endpoints for configuration and data

**Key Files**:

- `Program.cs` - Startup configuration and DI setup
- `Hubs/AgentHub.cs` - Agent communication hub
- `Hubs/ViewerHub.cs` - Viewer/browser communication hub
- `Hubs/DesktopHub.cs` - Desktop client communication hub
- `Services/` - Business logic (DataService, SessionRecording, etc.)
- `wwwroot/` - Static files and TypeScript viewer client

**Data Flow**:

1. Viewers connect via web browser → ViewerHub
2. Request sent to DesktopHub (device/caster)
3. DesktopHub requests screen capture from DesktopClient
4. DesktopClient streams frames back to ViewerHub
5. ViewerHub relays to browser viewer

---

### 2. **Desktop.Shared** (Class Library)

**Location**: `Desktop.Shared/`

**Purpose**: Shared abstractions and implementations for all desktop clients.

**Key Components**:

- **ScreenCaster** - Core screen capture orchestration
- **Viewer** - Handles individual viewer connections
- **DesktopHubConnection** - SignalR connection management
- **Message Handlers** - Process incoming DTOs from server
- **Dependencies**:
  - SkiaSharp (image processing)
  - Platform-specific screen capture implementations

**Key Responsibilities**:

1. **Screen Capture Loop**:
   - Continuously captures desktop frames
   - Detects screen changes using diff-detection
   - Encodes frames using JPEG compression
   - Chunks frames into 50KB pieces for transmission

2. **Viewer Management**:
   - Tracks connected viewers
   - Applies per-viewer quality settings
   - Monitors frame delivery and latency
   - Auto-adjusts quality based on network conditions

3. **Event Streaming**:
   - Uses `IAsyncEnumerable<byte[]>` for frame streaming
   - Implements backpressure (waits if viewer falls behind)
   - Tracks metrics: FPS, Mbps, latency

**ScreenCaster Flow**:

```
BeginScreenCasting(ScreenCastRequest)
  ↓
Open session, show indicator
  ↓
Send initial screen data (dimensions, display names)
  ↓
GetDesktopStream() - Async enumerable
  ├─ Capture frame
  ├─ Detect diff area
  ├─ Encode JPEG
  ├─ Chunk to 50KB
  └─ Yield frame bytes
  ↓
Loop until disconnect
```

---

### 3. **Desktop.Linux** (Windows Forms App)

**Location**: `Desktop.Linux/`

**Purpose**: Cross-platform desktop client using Avalonia framework.

**Technology Stack**:

- **Avalonia**: Cross-platform UI framework
- **SkiaSharp**: GPU-accelerated rendering
- **SignalR**: Real-time communication
- **.NET**: Cross-platform runtime

**Key Features**:

- Native look and feel on Linux/Windows
- Hardware-accelerated screen rendering
- Input injection (keyboard, mouse, touch)
- Clipboard synchronization
- Audio streaming
- File transfer support

**Startup Process**:

1. Build Avalonia app
2. Register dependency injection services
3. Load embedded server data (if available)
4. Initialize screen capturer (Linux-specific)
5. Start RemoteControl service
6. Connect to server via SignalR

---

### 4. **Desktop.Win** (WPF Application)

**Location**: `Desktop.Win/`

**Purpose**: Windows-specific desktop client with optimized native integration.

**Key Differences from Desktop.Linux**:

- Direct Windows API calls
- DirectX-based screen capture
- Windows service integration
- Windows session handling
- Native Windows dialogs

**Technologies**:

- **WPF**: Windows Presentation Foundation
- **DirectX**: GPU-accelerated capture
- **Win32 APIs**: Direct system integration

---

### 5. **Desktop.Core** (Class Library)

**Location**: `Desktop.Core/`

**Purpose**: Platform-agnostic core logic for desktop applications.

**Key Classes**:

**Conductor**:

- Central orchestrator for the desktop client
- Manages application mode (normal, service, etc.)
- Maintains viewer collection
- Handles events (ScreenCastRequested, ViewerAdded/Removed)
- Parses command-line arguments

**Viewer**:

- Represents a single remote viewer connection
- Manages screen frame queue
- Tracks FPS, bandwidth, latency
- Implements image quality auto-adjustment
- Queues frames for transmission
- Handles stalling detection

**CasterSocket**:

- Manages SignalR hub connection to server
- Routes DTOs to/from message handlers
- Implements connection/reconnection logic
- Idle timeout management

**ScreenCaster** (IScreenCaster):

- Initiates screen casting for a viewer
- Manages session lifecycle
- Shows/hides session indicator
- Coordinates between platform-specific capturer and Viewer

---

### 6. **Desktop.Native** (Class Library)

**Location**: `Desktop.Native/`

**Purpose**: Platform-specific native implementations.

**Implementations**:

- **Windows/**
  - DirectX screen capture
  - Cursor icon extraction
  - Session notification handling
  - Windows API integrations
- **Linux/**
  - X11/Wayland screen capture
  - Linux-specific input handling

---

### 7. **Desktop.UI** (Avalonia Controls)

**Location**: `Desktop.UI/`

**Purpose**: Reusable UI components for desktop clients.

**Components**:

- Custom controls for remote desktop rendering
- Connection UI components
- Status indicators
- Input handling controls

---

### 8. **Agent** (Console Application)

**Location**: `Agent/`

**Purpose**: Lightweight service agent for scripting and command execution.

**Capabilities**:

- Connect to server as an "Agent" (not a desktop viewer)
- Execute PowerShell/CMD commands
- Perform remote scripting
- Retrieve system information
- Auto-update mechanism
- Multi-platform support (Windows, Linux, macOS)

**Modes**:

- Windows Service (`UseWindowsService()`)
- Systemd Service (`UseSystemd()`)
- Console Application

**Key Features**:

- Script execution with authentication
- Command history and logging
- Registry operations (Windows)
- Process management
- File operations

---

### 9. **Shared** (Shared Class Library)

**Location**: `Shared/`

**Purpose**: Cross-cutting concerns and shared models.

**Contains**:

- **DTOs**: Data transfer objects for all hub communications
- **Interfaces**: Hub client interfaces (IAgentHubClient, IDesktopHubClient, IViewerHubClient)
- **Models**: Domain models (Device, Organization, User)
- **Enums**: Shared enumerations
- **Utilities**: Helper functions and extensions
- **Services**: Cross-platform utilities

---

## Communication Flow

### Remote Control Session - Attended Mode

```
1. VIEWER (Browser)
   └─> POST /api/RemoteControl/GetSessionInfo (session ID)

2. SERVER (ViewerHub)
   └─> ValidateAccess()
   └─> CreateSession()
   └─> Call DesktopHub.RequestScreenCast()

3. DESKTOP CLIENT (DesktopHub listener)
   └─> PromptUser() [if attended mode with notification]
   └─> User accepts
   └─> Call ScreenCaster.BeginScreenCasting()

4. SCREEN CASTER (Desktop.Shared)
   └─> Initialize viewer connection
   └─> GetDesktopStream() starts
   └─> Capture → Encode → Chunk → Yield

5. VIEWER receives stream
   └─> ProcessStream() decodes frames
   └─> Renders to canvas
   └─> Captures input (mouse, keyboard)
   └─> Sends input DTOs back to server

6. SERVER routes input DTOs
   └─> Call DesktopHub.SendDtoToClient()

7. DESKTOP CLIENT receives DTOs
   └─> MessageHandler processes DTO
   └─> Inject input (keyboard/mouse)
   └─> Update local state
```

### Agent Scripting Session

```
1. AGENT (connects to AgentHub)
   └─> SignalR connection
   └─> Awaits commands

2. SERVER (AgentHub)
   └─> ExecuteCommand() received from API or viewer

3. AGENT
   └─> Spawns PowerShell/CMD process
   └─> Captures stdout/stderr
   └─> Streams output back to server

4. SERVER
   └─> Relays to requesting client
```

---

## Data Models & DTOs

### Screen Casting DTOs

**CaptureFrame**:

```
├─ EncodedImageBytes (byte[]) - JPEG encoded image
├─ Top, Left, Width, Height - Frame position/size
├─ Sequence - Frame number
└─ Id - Unique identifier
```

**Frame Transmission**:

- Frames split into ~50KB chunks
- Each chunk includes: position, dimensions, sequence
- Reassembled on viewer side

### Session Models

**RemoteControlSession**:

```
├─ SessionId - Unique identifier
├─ OrganizationId - Tenant isolation
├─ DeviceId - Target device
├─ Mode - Attended/Unattended
├─ AccessKey - Security key
├─ StreamId - Current stream
├─ ViewerList - Connected viewers
└─ Metrics - Performance data
```

---

## Screen Capture Pipeline

### Windows (DirectX)

```
DirectX Device → GPU Memory
    ↓
GetDesktopTexture()
    ↓
Copy to CPU
    ↓
SkiaSharp Bitmap
    ↓
Diff Detection (compares with previous frame)
    ↓
Crop to changed area only
    ↓
JPEG Encode (SkiaSharp)
    ↓
Chunk to 50KB
    ↓
Stream to viewer
```

**Performance**:

- GPU-accelerated capture
- Adaptive quality (20-100)
- ~30-60 FPS typical

### Linux (X11/Wayland)

```
X11 Server / Wayland Compositor
    ↓
XGetImage() / Wayland API
    ↓
SkiaSharp Bitmap
    ↓
(Same as Windows from here)
```

---

## Quality Auto-Adjustment

**Viewer Class** monitors:

- **Latency**: Round-trip time for frame ACKs
- **Bandwidth**: Mbps based on frame transmission
- **FPS**: Actual frames per second achieved

**Algorithm**:

```
if (Latency > Threshold) {
    Quality -= 5  // Reduce quality
}
else if (FPS < 15 && Latency < 100ms) {
    Quality += 5  // Increase quality
}

Quality = Clamp(Quality, 20, 100)
```

---

## Authentication & Authorization

### Server Configuration

```json
{
  "DefaultOrganization": "Primary Org",
  "DbProvider": "sqlite",
  "KnownProxies": ["127.0.0.1", "172.28.0.1"]
}
```

### User Roles

1. **Server Admin**: Full server config access
2. **Organization Admin**: Organization-level management
3. **User**: Can initiate remote control sessions
4. **Device Owner**: Can manage their device

### Session Security

- **Attended**: User must approve on device
- **Unattended**: Access key required
- **API**: Token-based authentication
- **Chat**: Encrypted message transport

---

## Key Technologies

### Backend

| Technology            | Purpose                               |
| --------------------- | ------------------------------------- |
| ASP.NET Core 8+       | Web framework                         |
| SignalR Core          | Real-time bidirectional communication |
| Entity Framework Core | ORM for data access                   |
| Microsoft Identity    | Authentication                        |
| Blazor Server         | Interactive web UI                    |
| Serilog               | Structured logging                    |

### Desktop

| Technology          | Purpose                  |
| ------------------- | ------------------------ |
| Avalonia            | Cross-platform UI        |
| SkiaSharp           | GPU-accelerated graphics |
| DirectX (Windows)   | GPU screen capture       |
| X11/Wayland (Linux) | Screen capture           |
| SignalR Client      | Real-time communication  |

### Data

| Database   | Use Case                       |
| ---------- | ------------------------------ |
| SQLite     | Development, small deployments |
| SQL Server | Enterprise                     |
| PostgreSQL | Enterprise, Linux              |

---

## Deployment & Configuration

### Docker Deployment

```yaml
services:
  remotely:
    image: immybot/remotely
    ports:
      - "5000:5000"
    environment:
      - Remotely_DbProvider=sqlite
      - Remotely_DefaultOrganization=Default
    volumes:
      - ./data:/app/AppData
```

### Reverse Proxy Requirements

**Required Headers**:

- `X-Forwarded-Proto` - http/https
- `X-Forwarded-Host` - original hostname
- `X-Forwarded-For` - client IP

**Recommended**: Caddy (built-in support)

---

## Session Lifecycle

### Desktop Client Perspective

```
1. STARTUP
   ├─ Create ServiceCollection
   ├─ Register services
   ├─ Extract embedded server URL
   └─ Start DesktopHubConnection

2. CONNECT
   ├─ SignalR negotiation
   ├─ Register device with server
   └─ Await remote control requests

3. RECEIVE REQUEST
   ├─ Get ScreenCastRequest
   ├─ Create Viewer instance
   ├─ Initialize screen capturer
   └─ Start screen capture loop

4. CAPTURE & STREAM
   ├─ GetDesktopStream() yields frames
   ├─ Viewer receives & processes input
   ├─ Monitor performance metrics
   └─ Auto-adjust quality

5. DISCONNECT
   ├─ Viewer requests disconnect
   ├─ Stop frame capture
   ├─ Close connections
   └─ Notify server
```

---

## Performance Characteristics

### Metrics Tracked

```
┌─ Frames Per Second (FPS)
├─ Megabits Per Second (Mbps)
├─ Round Trip Latency (ms)
├─ Pending Frames (queue depth)
└─ GPU Acceleration Status
```

### Optimization Strategies

1. **Frame Diff**: Only send changed areas
2. **Chunking**: Split large frames into 50KB chunks
3. **Quality Adaptation**: Auto-adjust JPEG quality
4. **Backpressure**: Wait if viewer falls behind
5. **GPU Acceleration**: DirectX/Wayland for capture
6. **Stream Caching**: Cache desktop streams on server

---

## Error Handling & Resilience

### Connection Failures

```
Desktop → SignalR fails
    ↓
Exponential backoff retry (3 seconds initial)
    ↓
Repeat until successful
    ↓
Log all failures
```

### Viewer Stalling

```
Frame pending > 15 seconds
    ↓
Mark as stalled
    ↓
Log warning
    ↓
Continue (may disconnect if too stalled)
```

### Session Timeout

```
No activity > configurable timeout
    ↓
Graceful disconnect
    ↓
Cleanup resources
```

---

## Build & Debug

### Development Setup (Windows 11)

1. **Requirements**:
   - Visual Studio 2022 with .NET desktop development
   - Latest .NET SDK
   - Node.js LTS (for web assets)
   - Git

2. **Build**:

   ```bash
   git clone https://github.com/immense/Remotely --recurse
   dotnet build Remotely.sln
   ```

3. **Debug**:
   - Set startup project to Server
   - Server runs on https://localhost:5001
   - Desktop client connects to localhost by default
   - Agent connects as service/systemd

---

## Code Organization

```
Remotely/
├─ Agent/                    # Scripting agent
├─ Desktop.Core/             # Platform-agnostic core
├─ Desktop.Linux/            # Avalonia Linux client
├─ Desktop.Native/           # Platform-specific code
├─ Desktop.Shared/           # Shared screen casting logic
├─ Desktop.UI/               # Avalonia UI components
├─ Desktop.Win/              # Windows client
├─ Server/                   # ASP.NET Core backend
├─ Shared/                   # Shared models, DTOs, interfaces
├─ Tests/                    # Unit tests
└─ Utilities/                # Build/deployment scripts
```

---

## Extensibility Points

### Custom Message Handlers

Implement `IDtoMessageHandler` to process custom DTOs:

```csharp
public class CustomDtoHandler : IDtoMessageHandler
{
    public async Task HandleMessage(byte[] dtoBytes)
    {
        // Deserialize and handle
    }
}
```

### Platform-Specific Features

Implement interfaces in Native projects:

- `IScreenCapturer` - Custom screen capture
- `IClipboardService` - Platform clipboard
- `IKeyboardMouseInput` - Custom input injection

### Custom UI

Modify Blazor components in `Server/Components/`

---

## Security Considerations

✅ **Implemented**:

- ASP.NET Core Identity authentication
- Role-based authorization
- Attended mode user confirmation
- Access key for unattended sessions
- SSL/TLS encryption
- Database encryption for sensitive data
- Session isolation by organization
- Audit logging

⚠️ **Configuration Required**:

- Set strong admin password
- Enable HTTPS on reverse proxy
- Configure known proxy IPs
- Regular security updates
- Limit organization count in production

---

## Summary

Remotely is a sophisticated, production-grade remote desktop solution that:

1. **Separates Concerns**: Server hub, desktop clients, agents
2. **Scales Efficiently**: Multi-tenant architecture, caching
3. **Performs Well**: GPU acceleration, adaptive quality, frame diffing
4. **Remains Secure**: Identity integration, access control
5. **Stays Flexible**: Pluggable screen capture, input handling
6. **Deploys Easily**: Docker support, HTTPS ready

The architecture elegantly balances real-time performance with extensibility, making it suitable for both enterprise deployments and custom integrations.
