import { WebGPUResourceOptions } from './types';
import { WebGPUBindGroupLayout } from './webgpubindgrouplayout';

export type WebGPUPipelineLayoutOptions = WebGPUResourceOptions & {
  bindGroupLayouts: WebGPUBindGroupLayout[];
};

export class WebGPUPipelineLayout {
  private pipelineLayout: GPUPipelineLayout;

  public get layout() {
    return this.pipelineLayout;
  }

  public create(options: WebGPUPipelineLayoutOptions) {
    this.pipelineLayout = options.device.createPipelineLayout({
      label: options.label,
      bindGroupLayouts: options.bindGroupLayouts.map(bgl => bgl.layout),
    });
  }
}
