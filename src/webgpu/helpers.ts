export function supportsWebGPU(): boolean {
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (navigator.gpu) {
    return true;
  }
  return false;
}

export function createBuffer(array: ArrayBuffer, usage: GPUBufferUsageFlags, device: GPUDevice): GPUBuffer {
  const buffer = device.createBuffer({
    size: array.byteLength,
    usage,
  });

  device.queue.writeBuffer(buffer, 0, array);

  return buffer;
}
