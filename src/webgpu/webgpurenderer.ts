import {
  BufferDataTypeKind,
  Camera,
  CameraControls,
  ScalarType,
  WebGPUBindGroup,
  WebGPUBindGroupLayout,
  WebGPUBuffer,
  WebGPUContext,
  WebGPUPipelineLayout,
  WebGPURenderPipeline,
  WebGPUShader,
} from '@donnerknalli/webgpu-utils';
import { Vec2, vec3 } from 'wgpu-matrix';

export class WebGPURenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly webGPUContext: WebGPUContext;
  private presentationSize!: GPUExtent3DDict;
  private readonly depthOrArrayLayers = 1;
  private readonly sampleCount = 4;

  private renderTarget?: GPUTexture;
  private renderTargetView!: GPUTextureView;

  private currentTime = 0;
  private renderPipeline!: WebGPURenderPipeline;

  private uniformParamsBuffer!: WebGPUBuffer;
  private uniformParamsGroup!: WebGPUBindGroup;
  private readonly camera: Camera;
  private readonly cameraControls: CameraControls;
  private resolution: Vec2 = new Float32Array([0, 0]);
  private time = 0;

  public constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.webGPUContext = new WebGPUContext(canvas);
    this.camera = new Camera(45, canvas.width / canvas.height, 0.1, 1000);
    this.camera.translate(vec3.create(0, 0, 5));
    this.cameraControls = new CameraControls(canvas, this.camera);
  }

  private createUniformParamsBuffer() {
    this.uniformParamsBuffer = new WebGPUBuffer(
      this.webGPUContext,
      GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      'uniformBuffer',
    );
    this.uniformParamsBuffer.setData('resolution', {
      data: this.resolution,
      dataType: { elementType: ScalarType.Float32, bufferDataTypeKind: BufferDataTypeKind.Vec2 },
    });

    this.uniformParamsBuffer.setData('cameraPosition', {
      data: this.camera.eye,
      dataType: { elementType: ScalarType.Float32, bufferDataTypeKind: BufferDataTypeKind.Vec3 },
    });

    this.uniformParamsBuffer.setData('cameraRotation', {
      data: this.camera.viewMatrix,
      dataType: { elementType: ScalarType.Float32, bufferDataTypeKind: BufferDataTypeKind.Mat4x4 },
    });

    this.uniformParamsBuffer.setData('time', {
      data: this.time,
      dataType: { elementType: ScalarType.Float32, bufferDataTypeKind: BufferDataTypeKind.Scalar },
    });

    this.uniformParamsBuffer.writeBuffer();
  }

  private async initialize() {
    const context = await this.webGPUContext.create();
    if (!context) {
      throw new Error('Could not create WebGPU context');
    }

    const width = this.canvas.clientWidth * window.devicePixelRatio;
    const height = this.canvas.clientHeight * window.devicePixelRatio;

    this.resolution[0] = width;
    this.resolution[1] = height;

    this.createUniformParamsBuffer();

    this.presentationSize = { width, height, depthOrArrayLayers: this.depthOrArrayLayers };

    this.canvas.width = width;
    this.canvas.height = height;

    this.webGPUContext.gpuCanvasContext.configure({
      device: this.webGPUContext.device,
      format: this.webGPUContext.preferredCanvasFormat,
      alphaMode: 'opaque',
    });

    const resizeObserver = new ResizeObserver((entries) => {
      if (!Array.isArray(entries)) {
        return;
      }

      this.resize(new Float32Array([entries[0].contentRect.width, entries[0].contentRect.height]));
    });
    resizeObserver.observe(this.canvas);
  }

  private resize(newResolution: Vec2) {
    const newWidth = newResolution[0] * window.devicePixelRatio;
    const newHeight = newResolution[1] * window.devicePixelRatio;

    if (newWidth !== this.presentationSize.width || newHeight !== this.presentationSize.height) {
      this.resolution[0] = newWidth;
      this.resolution[1] = newHeight;

      this.canvas.width = newWidth;
      this.canvas.height = newHeight;
      this.presentationSize = { width: newWidth, height: newHeight, depthOrArrayLayers: this.depthOrArrayLayers };
      this.reCreateRenderTargets();

      this.uniformParamsBuffer.writeBuffer();
    }
  }

  private reCreateRenderTargets() {
    if (this.renderTarget !== undefined) {
      this.renderTarget.destroy();
    }

    /* render target */
    this.renderTarget = this.webGPUContext.device.createTexture({
      size: this.presentationSize,
      sampleCount: this.sampleCount,
      format: this.webGPUContext.preferredCanvasFormat,
      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    });
    this.renderTargetView = this.renderTarget.createView();
  }

  private async initializeResources() {
    const bindGroupLayout = new WebGPUBindGroupLayout(this.webGPUContext, [
      { binding: 0, visibility: GPUShaderStage.FRAGMENT, buffer: { type: 'uniform' } },
    ]);
    bindGroupLayout.createBindGroupLayout();

    this.uniformParamsGroup = new WebGPUBindGroup(this.webGPUContext, bindGroupLayout, [
      { binding: 0, resource: { buffer: this.uniformParamsBuffer.getRawBuffer() } },
    ]);
    this.uniformParamsGroup.createBindGroup();

    const pipelineLayout = new WebGPUPipelineLayout(this.webGPUContext, [bindGroupLayout]);
    pipelineLayout.createPipelineLayout();

    const vertexShader = new WebGPUShader(
      this.webGPUContext,
      new URL('./shaders/basic.vert.wgsl', window.location.href),
    );
    await vertexShader.createShaderModule();

    const fragmentShader = new WebGPUShader(
      this.webGPUContext,
      new URL('./shaders/basic.frag.wgsl', window.location.href),
    );
    await fragmentShader.createShaderModule();

    this.renderPipeline = new WebGPURenderPipeline(this.webGPUContext, pipelineLayout, vertexShader, fragmentShader);
    this.renderPipeline.addColorTargetState({ format: this.webGPUContext.preferredCanvasFormat });
    this.renderPipeline.setPrimitiveState({ topology: 'triangle-list' });
    this.renderPipeline.setMultisampleState({ count: this.sampleCount });
    this.renderPipeline.createRenderPipeline();
  }

  public async start() {
    await this.initialize();
    this.reCreateRenderTargets();
    await this.initializeResources();
    this.currentTime = performance.now();
    this.update();
  }

  private readonly update = () => {
    const beginFrameTime = performance.now();
    const duration = beginFrameTime - this.currentTime;
    this.currentTime = beginFrameTime;

    this.time += duration / 1000;

    this.uniformParamsBuffer.writeBuffer();

    this.render(duration);
    window.requestAnimationFrame(this.update);
  };

  private render(_deltaTime: number) {
    this.renderPass();
  }

  private renderPass() {
    // update uniform buffer
    this.uniformParamsBuffer.writeBuffer();

    let view: GPUTextureView;
    let resolveTarget: GPUTextureView | undefined;

    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (this.sampleCount > 1) {
      view = this.renderTargetView;
      resolveTarget = this.webGPUContext.gpuCanvasContext.getCurrentTexture().createView();
    } else {
      view = this.webGPUContext.gpuCanvasContext.getCurrentTexture().createView();
    }

    const renderPassDesc: GPURenderPassDescriptor = {
      colorAttachments: [
        { view, resolveTarget, clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }, loadOp: 'clear', storeOp: 'discard' },
      ],
    };

    const commandEncoder = this.webGPUContext.device.createCommandEncoder();
    const passEncoder = commandEncoder.beginRenderPass(renderPassDesc);
    passEncoder.setPipeline(this.renderPipeline.renderPipeLine);
    passEncoder.setBindGroup(0, this.uniformParamsGroup.bindGroup);
    passEncoder.draw(3, 1, 0, 0); // only 1 triangle
    passEncoder.end();

    this.webGPUContext.queue.submit([commandEncoder.finish()]);
  }
}
