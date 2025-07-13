# Custom Car Physics Simulation in Godot

This project is a demonstration of a custom car physics implementation in the Godot game engine, using the Jolt Physics engine for the underlying physics simulation.

## Features

*   **Detailed Wheel Simulation:** Each wheel is individually simulated with:
    *   **Suspension:** A spring and damper system for each wheel to handle bumps and uneven terrain.
    *   **Traction and Steering:** Realistic acceleration and steering forces are applied to the wheels.
    *   **Friction:** Rolling friction and lateral friction are simulated to provide a realistic driving feel.
*   **Dynamic Camera:** An orbiting camera that follows the car and can be controlled with the mouse. It automatically rotates to follow the car's direction when moving.
*   **Sound Effects:** The simulation includes some engine sounds that change with speed and acceleration, as well as collision sounds.

## Controls

| Action          | Key         |
| --------------- | ----------- |
| Accelerate      | W           |
| Reverse         | S           |
| Steer Left      | A           |
| Steer Right     | D           |
| Handbrake       | Space       |
| Toggle Lights   | L           |
| Toggle Highbeams| H           |

## How to Use

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    ```
2.  **Open the project in Godot:**
    *   Open the Godot Engine editor.
    *   Click on "Import" and select the `project.godot` file from the cloned repository.
3.  **Run the project:**
    *   Press the "Play" button (or F5) to run the `test.tscn` scene.
