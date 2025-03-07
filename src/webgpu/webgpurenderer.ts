import { BufferDataType, createContext, WebGPUBuffer, WebGPUContext } from '@donnerknalli/webgpu-utils';
import { Vec2 } from 'wgpu-matrix';
import { Camera } from './camera';
import { WebGPUBindGroup } from './webgpubindgroup';
import { WebGPUBindGroupLayout } from './webgpubindgrouplayout';
import { WebGPUPipelineLayout } from './webgpupipelinelayout';
import { WebGPURenderPipeline } from './webgpurenderpipeline';

export class WebGPURenderer {
  private readonly canvas: HTMLCanvasElement;
  private context!: WebGPUContext;
  private presentationSize!: GPUExtent3DDict;
  private readonly depthOrArrayLayers = 1;
  private sampleCount = 4;

  private renderTarget?: GPUTexture;
  private renderTargetView!: GPUTextureView;

  private depthTarget?: GPUTexture;
  private depthTargetView!: GPUTextureView;
  private currentTime = 0;
  private renderPipeline!: WebGPURenderPipeline;
  // private computePipeline: GPUComputePipeline;

  private uniformParamsBuffer!: WebGPUBuffer;
  private uniformParamsGroup!: WebGPUBindGroup;
  private camera: Camera;
  private resolution: Vec2 = new Float32Array([0, 0]);
  private time = 0;

  public constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.camera = new Camera(canvas, new Float32Array([0, 0, 5]), new Float32Array([0, 0]));
  }

  private createUniformParamsBuffer() {
    this.uniformParamsBuffer = new WebGPUBuffer(
      this.context,
      GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      'uniformBuffer',
    );
    this.uniformParamsBuffer.setData('resolution', {
      data: this.resolution,
      dataType: BufferDataType.Vec2OfFloat32,
    });

    this.uniformParamsBuffer.setData('cameraPosition', {
      data: this.camera.position,
      dataType: BufferDataType.Vec3OfFloat32,
    });

    this.uniformParamsBuffer.setData('cameraRotation', {
      data: this.camera.rotation,
      dataType: BufferDataType.Vec2OfFloat32,
    });

    this.uniformParamsBuffer.setData('time', {
      data: new Float32Array([this.time]),
      dataType: BufferDataType.Float32,
    });

    this.uniformParamsBuffer.writeBuffer();
  }

  private async initialize() {
    const context = await createContext(this.canvas);
    if (!context) {
      throw new Error('Could not create WebGPU context');
    }

    this.context = context;

    const width = this.canvas.clientWidth * window.devicePixelRatio;
    const height = this.canvas.clientHeight * window.devicePixelRatio;

    this.resolution[0] = width;
    this.resolution[1] = height;

    this.createUniformParamsBuffer();

    this.presentationSize = { width, height, depthOrArrayLayers: this.depthOrArrayLayers };

    this.canvas.width = width;
    this.canvas.height = height;

    this.context.gpuCanvasContext.configure({
      device: this.context.device,
      format: this.context.preferredCanvasFormat,
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
    }
  }

  private reCreateRenderTargets() {
    if (this.renderTarget !== undefined) {
      this.renderTarget.destroy();
    }

    if (this.depthTarget) {
      this.depthTarget.destroy();
    }

    /* render target */
    this.renderTarget = this.context.device.createTexture({
      size: this.presentationSize,
      sampleCount: this.sampleCount,
      format: this.context.preferredCanvasFormat,
      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    });
    this.renderTargetView = this.renderTarget.createView();

    /* depth target */
    this.depthTarget = this.context.device.createTexture({
      size: this.presentationSize,
      sampleCount: this.sampleCount,
      format: 'depth24plus-stencil8',
      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    });
    this.depthTargetView = this.depthTarget.createView();
  }

  private async initializeResources() {
    const bindGroupLayout = new WebGPUBindGroupLayout();
    bindGroupLayout.create({
      device: this.context.device,
      entries: [{ binding: 0, visibility: GPUShaderStage.FRAGMENT, buffer: { type: 'uniform' } }],
    });

    this.uniformParamsGroup = new WebGPUBindGroup();
    this.uniformParamsGroup.create({
      device: this.context.device,
      bindGroupLayout,
      entries: [{ binding: 0, resource: { buffer: this.uniformParamsBuffer.getRawBuffer() } }],
    });
    // }

    const pipelineLayout = new WebGPUPipelineLayout();
    pipelineLayout.create({ device: this.context.device, bindGroupLayouts: [bindGroupLayout] });

    this.renderPipeline = new WebGPURenderPipeline();
    await this.renderPipeline.create({
      device: this.context.device,
      vertexShaderFile: './shaders/basic.vert.wgsl',
      fragmentShaderFile: './shaders/basic.frag.wgsl',
      fragmentTargets: [{ format: this.context.preferredCanvasFormat }],
      sampleCount: this.sampleCount,
      pipelineLayout,
    });
  }

  public async start() {
    await this.initialize();
    this.reCreateRenderTargets();
    await this.initializeResources();
    this.currentTime = performance.now();
    this.update();
  }

  private update = () => {
    const beginFrameTime = performance.now();
    const duration = beginFrameTime - this.currentTime;
    this.currentTime = beginFrameTime;

    this.time += duration / 1000;

    this.render(duration);
    window.requestAnimationFrame(this.update);
    // const endFrameTime = performance.now();
    // const _frameDuration = endFrameTime - beginFrameTime;
  };

  private render(_deltaTime: number) {
    // this.computePass(deltaTime);
    this.renderPass();
  }

  private renderPass() {
    // update uniform buffer
    this.uniformParamsBuffer.writeBuffer();

    let view: GPUTextureView;
    let resolveTarget: GPUTextureView | undefined;

    if (this.sampleCount > 1) {
      view = this.renderTargetView;
      resolveTarget = this.context.gpuCanvasContext.getCurrentTexture().createView();
    } else {
      view = this.context.gpuCanvasContext.getCurrentTexture().createView();
    }

    const renderPassDesc: GPURenderPassDescriptor = {
      colorAttachments: [
        { view, resolveTarget, clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }, loadOp: 'clear', storeOp: 'discard' },
      ],
      // depthStencilAttachment: {
      //   view: this.depthTargetView,

      //   depthLoadOp: 'clear',
      //   depthClearValue: 1.0,
      //   depthStoreOp: 'store',

      //   stencilLoadOp: 'clear',
      //   stencilClearValue: 0,
      //   stencilStoreOp: 'store',
      // },
    };

    const commandEncoder = this.context.device.createCommandEncoder();
    const passEncoder = commandEncoder.beginRenderPass(renderPassDesc);
    passEncoder.setPipeline(this.renderPipeline.pipeline);
    passEncoder.setBindGroup(0, this.uniformParamsGroup.bindGroup);
    passEncoder.draw(3, 1, 0, 0); // only 1 triangle
    passEncoder.end();

    this.context.queue.submit([commandEncoder.finish()]);
  }

  // private computePass(deltaTime: number) {
  //   const commandEncoder = this.context.device.createCommandEncoder();
  //   const passEncoder = commandEncoder.beginComputePass();
  //   passEncoder.setPipeline(this.computePipeline);

  //   passEncoder.end();
  //   this.context.queue.submit([commandEncoder.finish()]);
  // }
}
