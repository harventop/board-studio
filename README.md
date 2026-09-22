# Board Studio

A SketchUp extension for creating parametric furniture and cabinetry panels by defining 3 points in 3D space.

## Features

- **3-Point Creation**: Define panel origin, length/width direction, and height with 3 clicks or via Measurements (VCB) input.
- **Parametric Settings**: Set panel thickness (mm), offset along length (mm), and offset along width/height (mm).
- **Two Workflow Commands**:
  - **New 3-Point Panel**: Opens the parameters dialog to configure dimensions before drawing.
  - **Next 3-Point Panel**: Skips the dialog and instantly draws using previous settings.
- **Live 3D Preview**: Real-time interactive preview showing panel boundaries, offsets, and extruded volume before finalizing.
- **Flip Extrusion**: Toggle extrusion direction dynamically using `Ctrl`.
- **Clean Geometry**: Automatically generates an isolated group with correct face normals and extrusion.

## Installation

### Method 1: Install `.rbz` (Recommended)

1. Generate `board_studio.rbz` by running `pack_extension.bat` (or use an existing `.rbz` build).
2. In SketchUp, navigate to **Extensions** > **Extension Manager**.
3. Click **Install Extension**.
4. Select `board_studio.rbz`.

### Method 2: Manual Installation (Development)

Copy `board_studio.rb` and the `board_studio/` directory into your SketchUp plugins folder:

- **Windows**:
  ```text
  %APPDATA%\SketchUp\SketchUp <Version>\SketchUp\Plugins\
  ```
- **macOS**:
  ```text
  ~/Library/Application Support/SketchUp <Version>/SketchUp/Plugins/
  ```

Restart SketchUp after copying.

## Usage

Access the tools via:
- **Extensions Menu**: `Extensions` > `New 3-Point Panel` / `Next 3-Point Panel`
- **Toolbar**: `Panel Creator` toolbar icons
