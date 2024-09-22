import { WebGPUResourceOptions } from './types';

type WebGPUBindGroupLayoutOptions = WebGPUResourceOptions & {
  entries: GPUBindGroupLayoutEntry[];
};

export class WebGPUBindGroupLayout {
  private bindGroupLayout!: GPUBindGroupLayout;

  public get layout() {
    return this.bindGroupLayout;
  }

  public create(options: WebGPUBindGroupLayoutOptions) {
    this.bindGroupLayout = options.device.createBindGroupLayout({
      label: options.label,
      entries: options.entries,
    });
  }
}
