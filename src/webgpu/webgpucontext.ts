export class WebGPURenderContext {
  private _canvas!: HTMLCanvasElement;
  private _device!: GPUDevice;
  private _queue!: GPUQueue;
  private _gpuCanvasContext!: GPUCanvasContext | null;
  private _presentationFormat!: GPUTextureFormat;
  private _adapterLimits!: GPUSupportedLimits;
  private _adapterInfo!: GPUAdapterInfo;

  public async initialize(canvas: HTMLCanvasElement) {
    this._canvas = canvas;

    const gpu: GPU = navigator.gpu;

    const adapter = await gpu.requestAdapter();
    if (!adapter) {
      throw new Error('Could not request Adapter');
    }

    this._adapterLimits = adapter.limits;
    this._adapterInfo = adapter.info;
    this._device = await adapter.requestDevice();
    this._queue = this._device.queue;

    this._gpuCanvasContext = this._canvas.getContext('webgpu');
    this._presentationFormat = gpu.getPreferredCanvasFormat();
  }

  public get device() {
    return this._device;
  }

  public get queue() {
    return this._queue;
  }

  public get presentationContext() {
    return this._gpuCanvasContext;
  }

  public get presentationFormat() {
    return this._presentationFormat;
  }
}
