using Godot;

using TangentMode = Godot.Curve.TangentMode;
public partial class AkashCurvePoint
{
    // Just for Fun
    public Vector2 position;
    public float left_tangent = 0;
    public float right_tangent = 0;
    public TangentMode left_mode = TangentMode.Free;
    public TangentMode right_mode = TangentMode.Free;
    public AkashCurvePoint(Vector2 position, float left_tangent = 0, float right_tangent = 0, TangentMode left_mode = 0, TangentMode right_mode = 0)
    {
        this.position = position;
        this.left_tangent = left_tangent;
        this.right_tangent = right_tangent;
        this.left_mode = left_mode;
        this.right_mode = right_mode;
    }
}
