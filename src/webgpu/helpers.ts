export function supportsWebGPU(): boolean {
  if (navigator.gpu) {
    return true;
  }
  return false;
}

export function createBuffer(array: ArrayBuffer, usage: GPUBufferUsageFlags, device: GPUDevice): GPUBuffer {
  try {
    const buffer = device.createBuffer({
      size: array.byteLength,
      usage,
    });

    device.queue.writeBuffer(buffer, 0, array);

    return buffer;
  } catch (e) {
    console.error(e);
  }
}
