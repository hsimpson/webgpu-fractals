import { WebGPUResourceOptions } from './types';
import { WebGPUPipelineLayout } from './webgpupipelinelayout';
import { createShaderModuleFromPath } from './webgpushader';

type WebGPURenderPipelineOptions = WebGPUResourceOptions & {
  sampleCount: number;
  vertexShaderFile: string;
  fragmentShaderFile: string;
  fragmentTargets: GPUColorTargetState[];
  pipelineLayout?: WebGPUPipelineLayout;
};

export class WebGPURenderPipeline {
  private renderPipeline!: GPURenderPipeline;

  public get pipeline() {
    return this.renderPipeline;
  }

  public async create(options: WebGPURenderPipelineOptions) {
    this.renderPipeline = options.device.createRenderPipeline({
      label: options.label,
      layout: options.pipelineLayout?.layout ?? 'auto',
      vertex: {
        module: await createShaderModuleFromPath(options.vertexShaderFile, options.device),
        entryPoint: 'main',
      },
      fragment: {
        module: await createShaderModuleFromPath(options.fragmentShaderFile, options.device),
        entryPoint: 'main',
        targets: options.fragmentTargets,
      },
      primitive: {
        topology: 'triangle-list',
      },
      multisample: {
        count: options.sampleCount,
      },
    });
  }
}
