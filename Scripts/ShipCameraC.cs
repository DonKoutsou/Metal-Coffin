using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

public partial class ShipCameraC : Camera2D
{
    [Export]    
    Control Background;
    [Export] 
    Node2D CityLines;
    [Export]
    Control Clouds;
    [Export]
    Control Ground;

    [Signal]
    public delegate void ZoomChangedEventHandler(float NewVal);
    [Signal]
    public delegate void PositionChangedEventHandler(float NewVal);

    private Vector2 start_zoom;
    private float start_dist;
    private bool GridShowing = false;
    private float shakestr = 0f;
    private float custom_time = 0f;
    private Tween FrameTween;
    private Tween stattween;

    public static ShipCameraC Instance;

    public override void _Ready(){
        Instance = this;
        ShaderMaterial CloudMat = (ShaderMaterial)Clouds.Material;
        CloudMat.SetShaderParameter("offset", GlobalPosition / 1500);

        ShaderMaterial GroundMat = (ShaderMaterial)Ground.Material;
        GroundMat.SetShaderParameter("offset", GlobalPosition / 1500);
    }

    public static ShipCameraC GetInstance(){
        return Instance;
    }

    private int ZoomStage = 1;
    private float ZoomStageMulti = 0.5f;
    private Tween ZoomTw;
    private Vector2 prevzoom = new Vector2(1, 1);
    private void _HANDLE_ZOOM(float zoomval){
        if (ZoomTw != null && ZoomTw.IsRunning())
        {
            ZoomTw.Kill();
        }

        ZoomTw = CreateTween();
        ZoomTw.SetEase(Tween.EaseType.Out);
        ZoomTw.SetTrans(Tween.TransitionType.Quart);

        Vector2 newzoom = (prevzoom * new Vector2(zoomval, zoomval)).Clamp(new Vector2(0.045f, 0.045f), new Vector2(5, 5));
        GD.Print(newzoom);
        Callable callable = new Callable(this, MethodName.UpdateZoom);
        ZoomTw.TweenMethod(callable, Zoom, newzoom, 1f);
        prevzoom = newzoom;
        ZoomTw.SetProcessMode(Tween.TweenProcessMode.Physics);
        CallDeferred("OnZoomChanged", newzoom);
    }

    private void UpdateZoom(Vector2 NewZoom)
    {
        Zoom = NewZoom;
        foreach (var g in GetTree().GetNodesInGroup("MapLines"))
        {
            SetShaderParameter(g, "line_width", Mathf.Lerp(0.01f, 0.001f, Zoom.X / 2));
        }
        GetTree().CallGroup("LineMarkers", "CamZoomUpdated", Zoom.X);
        GetTree().CallGroup("ZoomAffected", "UpdateCameraZoom", Zoom.X);
        EmitSignal(nameof(ZoomChanged), Zoom.X);
        
        _UpdateMapGridVisibility();
    }

    private Dictionary<int, Vector2> touch_points = new Dictionary<int, Vector2>();
    private void _HANDLE_TOUCH(InputEventScreenTouch ev)
    {
        if (ev.Pressed)
        {
            touch_points[ev.Index] = ev.Position;
        }
        else
        {
            touch_points.Remove(ev.Index);
        }

        if (touch_points.Count == 2)
        {
            var touch_point_positions = new List<Vector2>(touch_points.Values);
            start_dist = touch_point_positions[0].DistanceTo(touch_point_positions[1]);
            start_zoom = Zoom;
        }
    }

    private void _HANDLE_DRAG(InputEventScreenDrag ev)
    {
        touch_points[ev.Index] = ev.Position;

        if (touch_points.Count == 2)
        {
            var touch_point_positions = new List<Vector2>(touch_points.Values);
            float current_dist = touch_point_positions[0].DistanceTo(touch_point_positions[1]);
            float zoom_factor = start_dist / current_dist;

            Zoom = (start_zoom / zoom_factor).Clamp(new Vector2(0.045f, 0.045f), new Vector2(2.1f, 2.1f));

            CallDeferred("OnZoomChanged", Zoom);
            _UpdateMapGridVisibility();
        }
        else
        {
            UpdateCameraPos(ev.Relative);
        }
    }

    private void OnZoomChanged(Vector2 NewZoom)
    {
        foreach (var g in GetTree().GetNodesInGroup("MapLines"))
        {
            SetShaderParameter(g, "line_width", Mathf.Lerp(0.01f, 0.001f, NewZoom.X / 2));
        }
        GetTree().CallGroup("LineMarkers", "CamZoomUpdated", NewZoom.X);
        GetTree().CallGroup("ZoomAffected", "UpdateCameraZoom", NewZoom.X);
        EmitSignal(nameof(ZoomChanged), NewZoom.X);
    }

    private async Task _UpdateMapGridVisibility()
    {
        if (Zoom.X < 0.5f && !GridShowing)
        {
            Tween mtw = CreateTween();
            mtw.TweenProperty(CityLines, "modulate", new Color(1, 1, 1, 1), 0.5f);
            Tween tw = CreateTween();
            tw.TweenProperty(Background, "modulate", new Color(1, 1, 1, 1), 0.5f);
            GridShowing = true;

            await ToSignal(tw, "finished");

            Clouds.Visible = false;
            Ground.Visible = false;
        }
        else if (Zoom.X >= 0.5f && GridShowing)
        {
            Clouds.Visible = true;
            Ground.Visible = true;
            Tween tw = CreateTween();
            tw.TweenProperty(Background, "modulate", new Color(1, 1, 1, 0), 0.5f);
            Tween mtw = CreateTween();
            mtw.TweenProperty(CityLines, "modulate", new Color(1, 1, 1, 0), 0.5f);
            GridShowing = false;
        }
    }

    

    private void UpdateCameraPos(Vector2 relativeMovement)
    {
        if (FrameTween != null && FrameTween.IsRunning())
        {
            FrameTween.Kill();
        }

        float maxPosY = 999999;
        float vpsizehalf = GetViewportRect().Size.X / 2;
        Vector2 maxPosX = new Vector2(vpsizehalf - 11000, vpsizehalf + 11000);
        Vector2 rel = relativeMovement / Zoom;
        Vector2 newPos = new Vector2(
            Mathf.Clamp(Position.X - rel.X, maxPosX.X, maxPosX.Y),
            Mathf.Clamp(Position.Y - rel.Y, -maxPosY, 1000));

        if (newPos.X != Position.X)
        {
            Position = newPos;
        }

        if (newPos.Y != Position.Y)
        {
            Position = newPos;
        }

        SetShaderParameter(Clouds, "offset", GlobalPosition / 1500);
        SetShaderParameter(Ground, "offset", GlobalPosition / 1500);

        EmitSignal(nameof(PositionChanged), Position);
    }

    public void ApplyShake()
    {
        shakestr = 2;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (!SimulationManageC.IsPaused())
        {
            custom_time += (float)delta * SimulationManageC.SimSpeed();
            SetShaderParameter(Clouds, "custom_time", custom_time);
        }
        if (shakestr > 0.0f)
        {
            shakestr = (float)Mathf.Lerp(shakestr, 0, 5.0f * delta);
            Vector2 of = RandomOffset();
            Offset = of;
        }
        //else{
        //    Vector2 of = RandomOffset2();
        ///    Offset = of;
        //}
           
        Vector2 rel = Vector2.Zero;

        if (Input.IsActionPressed("MapDown"))
        {
            rel.Y -= 10;
        }
        if (Input.IsActionPressed("MapUp"))
        {
            rel.Y += 10;
        }
        if (Input.IsActionPressed("MapRight"))
        {
            rel.X -= 10;
        }
        if (Input.IsActionPressed("MapLeft"))
        {
            rel.X += 10;
        }
        if (Input.IsActionPressed("ZoomIn"))
        {
            _HANDLE_ZOOM(1.1f);
        }
        if (Input.IsActionPressed("ZoomOut"))
        {
            _HANDLE_ZOOM(0.9f);
        }

        if (rel != Vector2.Zero)
        {
            UpdateCameraPos(rel);
        }
    }

    private Vector2 RandomOffset()
    {
        return new Vector2((float)GD.RandRange((double)-shakestr, shakestr), (float)GD.RandRange((double)-shakestr, shakestr));
    }
    Vector2 prev = Vector2.Zero;
    private Vector2 RandomOffset2()
    {
        float x = Mathf.Clamp((float)GD.RandRange(prev.X - 0.1, prev.X + 0.1), -10, 10);
        float y = Mathf.Clamp((float)GD.RandRange(prev.Y - 0.1, prev.Y + 0.1), -10, 10);
        prev = new Vector2(x, y);
        return prev;
    }

    public void ShowStation()
    {
        stattween = CreateTween();
        var stations = GetTree().GetNodesInGroup("CAPITAL");
        Vector2 stationpos = Vector2.Zero;

        foreach (Node2D g in stations)
        {
            if ((string)g.Call("GetSpotName") == "Dormak")
            {
                stationpos = g.GlobalPosition;
                break;
            }
        }
        stattween.SetTrans(Tween.TransitionType.Expo);
        stattween.TweenProperty(this, "GlobalPosition", stationpos, 6);

        if (Zoom.X > 1)
        {
            _HANDLE_ZOOM(0.05f);
        }
    }

    public void ShowArmak()
    {
        stattween = CreateTween();
        var stations = GetTree().GetNodesInGroup("CITY_CENTER");
        Vector2 stationpos = Vector2.Zero;

        foreach (Node2D g in stations)
        {
            if ((string)g.Call("GetSpotName") == "Armak")
           {
              stationpos = g.GlobalPosition;
                break;
            }
        }
        stattween.SetTrans(Tween.TransitionType.Expo);
        stattween.TweenProperty(this, "GlobalPosition", stationpos, 6);

        if (Zoom.X > 1)
        {
            _HANDLE_ZOOM(0.05f);
        }
    }

    public void FrameCamToPlayer()
    {
        if (stattween != null && stattween.IsRunning()){
            stattween.Kill();
        }

        FrameTween = CreateTween();
        Vector2 plpos = GetNode<Node2D>("../PlayerShip").GlobalPosition;
        FrameTween.SetTrans(Tween.TransitionType.Quad);
        FrameTween.SetEase(Tween.EaseType.Out);

        Callable callable = new Callable(this, MethodName.ForceCamPosition);

        FrameTween.TweenMethod(callable, GlobalPosition, plpos, 6);
    }

    public void FrameCamToPos(Vector2 pos, float OverrideTime = 1, bool Unzoom = true)
    {
        if (stattween != null && stattween.IsRunning())
        {
            stattween.Kill();
        }

        FrameTween = CreateTween();
        FrameTween.SetTrans(Tween.TransitionType.Quad);
        FrameTween.SetEase(Tween.EaseType.Out);

        Callable callable = new Callable(this, MethodName.ForceCamPosition);

        FrameTween.TweenMethod(callable, GlobalPosition, pos, OverrideTime);

        if (Unzoom && Zoom.X > 1)
        {
            _HANDLE_ZOOM(0.05f);
        }
    }

    public void ForceCamPosition(Vector2 Pos)
    {
        GlobalPosition = Pos;
        SetShaderParameter(Clouds, "offset", GlobalPosition / 1500);
        SetShaderParameter(Ground, "offset", GlobalPosition / 1500);
    }

    void SetShaderParameter(Node node, string parameter, Variant value)
    {
        Material material = (Material)node.Get("material");
        if (material != null)
        {
            //GD.Print("UpdatedShader");
            ShaderMaterial sm = (ShaderMaterial)material;
            sm.SetShaderParameter(parameter, value);
        }
    }

    void SetShaderParameter(string path, string parameter, Variant value)
    {
        Node node = GetNode(path);
        SetShaderParameter(node, parameter, value);
    }
}