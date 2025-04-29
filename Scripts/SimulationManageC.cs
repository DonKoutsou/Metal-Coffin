using Godot;
using System;

public partial class SimulationManageC : Node
{
    static bool Paused = false;
    static float SimulationSpeed  = 0.5f;

    public override void _Ready()
    {
        base._Ready();
    }

    public static float SimSpeed(){
        return SimulationSpeed;
    }

    public static bool IsPaused(){
        return Paused;
    }
    
    public void TogglePause(bool t){
        Paused = t;
    }

    public void SpeedToggle(bool t)
    {
        if (t)
		    SimulationSpeed = 5;
        else
            SimulationSpeed = 0.2f;
    }
	
}
