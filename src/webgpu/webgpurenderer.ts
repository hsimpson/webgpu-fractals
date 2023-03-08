import { WebGPURenderContext } from './webgpucontext';

export class WebGPURenderer {
  private readonly canvas: HTMLCanvasElement;
  private readonly context = new WebGPURenderContext();
  private presentationSize: GPUExtent3DDict;
  private readonly depthOrArrayLayers = 1;
  private readonly sampleCount = 4;

  private renderTarget: GPUTexture;
  private renderTargetView: GPUTextureView;

  private depthTarget: GPUTexture;
  private depthTargetView: GPUTextureView;
  private currentTime = 0;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
  }

  private async initialize() {
    await this.context.initialize(this.canvas);

    const width = this.canvas.clientWidth * window.devicePixelRatio;
    const height = this.canvas.clientHeight * window.devicePixelRatio;
    this.presentationSize = {
      width,
      height,
      depthOrArrayLayers: this.depthOrArrayLayers,
    };

    this.canvas.width = width;
    this.canvas.height = height;

    this.context.presentationContext.configure({
      device: this.context.device,
      format: this.context.presentationFormat,
      alphaMode: 'opaque',
    });

    const resizeObserver = new ResizeObserver(entries => {
      if (!Array.isArray(entries)) {
        return;
      }

      this.resize(entries[0].contentRect.width * window.devicePixelRatio, entries[0].contentRect.height * window.devicePixelRatio);
    });
    resizeObserver.observe(this.canvas);
  }

  private resize(width: number, height: number) {
    if (width !== this.presentationSize.width || height !== this.presentationSize.height) {
      // console.log(`Resizing canvas to ${width}x${height}`);
      this.canvas.width = width;
      this.canvas.height = height;
      this.presentationSize = {
        width,
        height,
        depthOrArrayLayers: this.depthOrArrayLayers,
      };
      this.reCreateRenderTargets();
    }
  }

  private reCreateRenderTargets() {
    if (this.renderTarget) {
      this.renderTarget.destroy();
    }
    if (this.depthTarget) {
      this.depthTarget.destroy();
    }

    /* render target */
    this.renderTarget = this.context.device.createTexture({
      size: this.presentationSize,
      sampleCount: this.sampleCount,
      format: this.context.presentationFormat,
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

  public async start() {
    await this.initialize();
    this.reCreateRenderTargets();
    // await this.initializeResources();
    this.currentTime = performance.now();
    this.update();
  }

  private update = () => {
    const beginFrameTime = performance.now();
    const duration = beginFrameTime - this.currentTime;
    this.currentTime = beginFrameTime;

    this.render(duration);
    window.requestAnimationFrame(this.update);
    const endFrameTime = performance.now();
    const frameDuration = endFrameTime - beginFrameTime;
  };

  private render(deltaTime: number) {
    this.renderPass();
  }

  private renderPass() {
    const colorAttachment: GPURenderPassColorAttachment = {
      view: this.context.presentationContext.getCurrentTexture().createView(),
      clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
      loadOp: 'clear',
      storeOp: 'store',
    };

    if (this.sampleCount > 1) {
      colorAttachment.view = this.renderTargetView;
      colorAttachment.resolveTarget = this.context.presentationContext.getCurrentTexture().createView();
    }

    const depthAttachment: GPURenderPassDepthStencilAttachment = {
      view: this.depthTargetView,

      depthLoadOp: 'clear',
      depthClearValue: 1.0,
      depthStoreOp: 'store',

      stencilLoadOp: 'clear',
      stencilClearValue: 0,
      stencilStoreOp: 'store',
    };

    const renderPassDesc: GPURenderPassDescriptor = {
      colorAttachments: [colorAttachment],
      depthStencilAttachment: depthAttachment,
    };

    const commandEncoder = this.context.device.createCommandEncoder();
    const passEncoder = commandEncoder.beginRenderPass(renderPassDesc);

    passEncoder.end();

    this.context.queue.submit([commandEncoder.finish()]);
  }
}
