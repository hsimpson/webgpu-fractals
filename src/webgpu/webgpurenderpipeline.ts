type WebGPURenderPipelineOptions = {
  sampleCount: number;
  vertexModule: GPUShaderModule;
  fragmentModule: GPUShaderModule;
  fragmentTargets: GPUColorTargetState[];
};

export class WebGPURenderPipeline {
  constructor(private readonly device: GPUDevice, private readonly options: WebGPURenderPipelineOptions) {}

  public create() {
    return this.device.createRenderPipeline({
      layout: 'auto',
      vertex: {
        module: this.options.vertexModule,
        entryPoint: 'main',
      },
      fragment: {
        module: this.options.fragmentModule,
        entryPoint: 'main',
        targets: this.options.fragmentTargets,
      },
      primitive: {
        topology: 'triangle-list',
      },
      multisample: {
        count: this.options.sampleCount,
      },
    });
  }
}
