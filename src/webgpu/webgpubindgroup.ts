import { WebGPUResourceOptions } from './types';
import { WebGPUBindGroupLayout } from './webgpubindgrouplayout';

type WebGPUBindGroupOptions = WebGPUResourceOptions & {
  bindGroupLayout: WebGPUBindGroupLayout;
  entries: GPUBindGroupEntry[];
};

export class WebGPUBindGroup {
  private group!: GPUBindGroup;

  public get bindGroup() {
    return this.group;
  }

  public create(options: WebGPUBindGroupOptions) {
    this.group = options.device.createBindGroup({
      label: options.label,
      layout: options.bindGroupLayout.layout,
      entries: options.entries,
    });
  }
}
