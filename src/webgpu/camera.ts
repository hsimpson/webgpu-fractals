import { Vec2, Vec3, vec2 } from 'wgpu-matrix';

export class Camera {
  private currentMousePosition: Vec2 = vec2.create();

  public constructor(
    canvas: HTMLCanvasElement,
    private cameraPosition: Vec3,
    private cameraRotation: Vec2,
  ) {
    canvas.addEventListener('wheel', this.onMouseWheel);
    canvas.addEventListener('mousemove', this.onMouseMove);
    document.addEventListener('keydown', this.onKeyDown);
    document.addEventListener('keyup', this.onKeyup);
  }

  private onMouseWheel = (event: WheelEvent) => {
    this.cameraPosition[2] = this.cameraPosition[2] + event.deltaY * 0.01;
  };

  private onMouseMove = (event: MouseEvent) => {
    const currentPos: Vec2 = new Float32Array([event.clientX, event.clientY]);
    if (event.buttons === 1) {
      const offset = vec2.subtract(currentPos, this.currentMousePosition);
      vec2.scale(offset, 0.005, offset);
      vec2.add(this.cameraRotation, [-offset[1], -offset[0]], this.cameraRotation);
      // console.log(cameraRotation);
    }
    this.currentMousePosition = currentPos;
  };

  private onKeyDown = (event: KeyboardEvent) => {
    const movementSpeed = 0.25;

    let x = this.cameraPosition[0];
    let y = this.cameraPosition[1];

    switch (event.key) {
      case 'w':
        y += movementSpeed;
        break;
      case 's':
        y -= movementSpeed;
        break;
      case 'a':
        x -= movementSpeed;
        break;
      case 'd':
        x += movementSpeed;
        break;
    }

    this.cameraPosition[0] = x;
    this.cameraPosition[1] = y;
  };

  private onKeyup = (_event: KeyboardEvent) => {
    //
  };

  public get position(): Vec3 {
    return this.cameraPosition;
  }

  // public get target(): Vec3 {
  //   return this.cameraTarget;
  // }

  public get rotation(): Vec2 {
    return this.cameraRotation;
  }
}
